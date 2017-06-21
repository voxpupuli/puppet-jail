require 'tempfile'

Puppet::Type.type(:jail).provide(:pyiocage) do
  desc 'Manage jails using iocage(8)'
  confine    kernel: :freebsd
  defaultfor kernel: :freebsd

  commands iocage: '/usr/local/bin/iocage'

  mk_resource_methods

  def self.jail_list
    output = execute('/usr/local/bin/iocage list -l', override_locale: false).split("\n")
    output.shift

    # Strip the leading and trailing pipe character from the lines to avoid
    # splitting the pipe thats in the interface/address specification.
    output.map! { |i| i.gsub(%r{^\|}, '') }
    output.map! { |i| i.gsub(%r{\|$}, '') }

    fields = output.shift.split(' | ').map do |i|
      next if i.empty?
      i.downcase.strip.rstrip.to_sym
    end.compact

    data = []

    output.each do |j|
      jail_data = {}
      values = j.split(' | ').map do |i|
        next if i.empty?
        i.strip.rstrip
      end.compact

      iocage_jail_list_regex = %r{^\s+}
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
        provider: :pyiocage,
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
    output = execute("/usr/local/bin/iocage get all #{jailname}", override_locale: false)
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
    iocage(['set', "#{property}=#{value}", resource[:name]])
  end

  def state=(value)
    @property_flush[:state] = value
  end

  def boot=(value)
    @property_flush[:boot] = value
  end

  def ip4_addr=(value)
    @property_flush[:ip4_addr] = value
  end

  def ip6_addr=(value)
    @property_flush[:ip6_addr] = value
  end

  def hostname=(value)
    @property_flush[:hostname] = value
  end

  def jail_zfs=(value)
    @property_flush[:jail_zfs] = value
  end

  def jail_zfs_dataset=(value)
    @property_flush[:jail_zfs_dataset] = value
  end

  def flush
    if @property_flush
      Puppet.debug "JailIocage(#flush): #{@property_flush}"

      pre_start_properties = [
        :boot,
        :ip4_addr,
        :ip6_addr,
        :hostname,
        :jail_zfs,
        :jail_zfs_dataset
      ]

      case resource[:ensure]
      when :absent
        iocage(['stop', resource[:name]])
        iocage(['destroy', '-f', resource[:name]])
      when :present
        iocage(['create', '-c', "tag=#{resource[:name]}"])
      end

      if resource[:state] == :up && resource[:ensure] == :present
        pre_start_properties.each do |p|
          set_property(p.to_s, resource[p]) if resource[p]
        end
        iocage(['start', resource[:name]])
        if resource[:user_data]
          tmpfile = Tempfile.new('puppet-iocage')
          tmpfile.write(resource[:user_data])
          tmpfile.close
          execute("/usr/local/bin/iocage exec #{resource[:name]} /bin/sh",
                  stdinfile: tmpfile.path,
                  override_locale: false)
          tmpfile.delete
        end
      end

      need_restart = false
      pre_start_properties.each do |p|
        if @property_flush[p]
          need_restart = true
          set_property(p.to_s, @property_flush[p])
        end
      end

      if @property_flush[:state]
        case resource[:state]
        when :up
          need_restart = false
          iocage(['start', resource[:name]])
        when :down
          need_restart = false
          iocage(['stop', resource[:name]])
        end
      end

      restart if need_restart
    end
    @property_hash = resource.to_hash
  end
end
