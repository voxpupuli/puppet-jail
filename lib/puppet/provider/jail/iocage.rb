require 'tempfile'

Puppet::Type.type(:jail).provide(:iocage) do
  desc 'Manage jails using iocage(8)'
  confine    kernel: :freebsd
  defaultfor kernel: :freebsd

  commands iocage: '/usr/local/sbin/iocage'

  mk_resource_methods

  def self.jail_list
    output = iocage(['list']).split("\n")
    fields = output.shift.split.map { |i| i.downcase.to_sym }

    data = []

    output.each do |j|
      jail_data = {}
      values = j.split

      iocage_jail_list_regex = %r{^(-|[0-9]+)\s+([[:xdigit:]]{8}-([[:xdigit:]]{4}-){3})[[:xdigit:]]{12}\s+(on|off)\s+(up|down)\s+.+$}
      next if iocage_jail_list_regex.match(j).nil?

      values.each_index do |i|
        jail_data[fields[i]] = values[i]
      end
      data << jail_data
    end

    data
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov
      end
    end
  end

  def self.instances
    jail_list.map do |j|
      jail_properties = {
        provider: :iocage,
        ensure: :present,
        name: j[:tag],
        state: j[:state],
        boot: j[:boot]
      }

      jail_properties[:jid] = j[:jid] if j[:jid] != '-'

      all_properties = get_jail_properties(j[:tag])

      extra_properties = [
        :ip4_addr,
        :ip6_addr,
        :hostname,
        :jail_zfs,
        :jail_zfs_dataset
      ]

      extra_properties.each do |p|
        jail_properties[p] = all_properties[p.to_s]
      end

      debug jail_properties

      new(jail_properties)
    end
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def self.get_jail_properties(jailname)
    data = {}
    output = iocage(['get', 'all', jailname])
    output.lines.each do |l|
      key, value = l.split(':', 2)
      data[key] = value.chomp
    end
    data.reject! { |k, v| k.nil? || v.nil? }

    debug data

    data
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def running?
    @property_hash[:state] == :up
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def restart
    iocage(['stop', resource[:name]])
    iocage(['start', resource[:name]])
  end

  def set_property(property, value)
    return unless @property_hash[property.to_sym] == value
    iocage(['set', "#{property}=#{value}", resource[:name]])
  end

  def flush
    require 'pp'

    if @property_hash
      Puppet.debug "JailIocage(#flush): #{@property_hash}"

      pre_start_properties = [
        :boot,
        :ip4_addr,
        :ip6_addr,
        :hostname,
        :jail_zfs,
        :jail_zfs_dataset
      ]

      need_restart = false

      if resource[:ensure] == :present

        # Create the jail if necessary
        unless @property_hash[:ensure] == :present
          iocage(['create', '-c', "tag=#{resource[:name]}"])
          just_created = true
        else
          just_created = false
        end

        # Set the desired properties
        pre_start_properties.each do |p|
          if resource[p]
            set_property(p.to_s, resource[p])

            # If the jail is already up, then we should restart it after the
            # properties have been set
            if @property_hash[:state] == 'up'
              if @property_hash[p] != resource[p]
              need_restart = true
              end
            end
          end

        end

        case resource[:state]
        when 'up'
          unless @property_hash[:state] == 'up'
            iocage(['start', resource[:name]])
          end

          if resource[:user_data] and just_created
            tmpfile = Tempfile.new('puppet-iocage')
            tmpfile.write(resource[:user_data])
            tmpfile.close
            execute("/usr/local/sbin/iocage exec #{resource[:name]} /bin/sh",
                    stdinfile: tmpfile.path)
            tmpfile.delete
          end
        when 'down'
          unless @property_hash[:state] == 'down'
            iocage(['stop', resource[:name]])
          end
        end

      elsif resource[:ensure] == :absent
        iocage(['stop', resource[:name]]) unless @property_hash[:state] == 'down'
        iocage(['destroy', '-f', resource[:name]])
      end

      restart if need_restart
    end
    @property_hash = resource.to_hash
  end
end
