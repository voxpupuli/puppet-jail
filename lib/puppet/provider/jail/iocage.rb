require 'tempfile'

Puppet::Type.type(:jail).provide(:iocage) do

  desc "Manage jails using iocage(8)"
  confine    :kernel => :freebsd
  defaultfor :kernel => :freebsd

  commands :iocage => '/usr/local/sbin/iocage'

  mk_resource_methods

  def self.jail_list
    output = iocage(['list']).split("\n")
    fields = output.shift.split().map {|i| i.downcase.to_sym }

    data = []

    output.each {|j|
      jail_data = {}
      values = j.split()

      iocage_jail_list_regex = /^(-|[0-9]+)\s+([[:xdigit:]]{8}-([[:xdigit:]]{4}-){3})[[:xdigit:]]{12}\s+(on|off)\s+(up|down)\s+.+$/
      next if iocage_jail_list_regex.match(j) == nil

      values.each_index {|i|
        jail_data[fields[i]] = values[i]
      }
      data << jail_data
    }

    return data
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def self.instances
    jail_list.collect do |j|
      jail_properties = {
        :provider         => :iocage,
        :ensure           => :present,
        :name             => j[:tag],
        :state            => j[:state],
        :boot             => j[:boot],
      }

      if j[:jid] != '-'
        jail_properties[:jid] = j[:jid]
      end

      all_properties = get_jail_properties(j[:tag])

      extra_properties = [
          :ip4_addr,
          :ip6_addr,
          :hostname,
          :jail_zfs,
          :jail_zfs_dataset,
      ]

      extra_properties.each {|p|
        jail_properties[p] = all_properties[p.to_s]
      }

      debug jail_properties

      new(jail_properties)
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.get_jail_properties(jailname)
    data = {}
    output = iocage(['get','all',jailname])
    output.lines.each {|l|
      key, value = l.split(':', 2)
      data[key] = value.chomp
    }
    data.reject! {|k,v| k == nil or v == nil}

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
          :jail_zfs_dataset,
      ]

      if @property_flush[:ensure]
        case resource[:ensure]
        when :absent
          iocage(['stop', resource[:name]])
          iocage(['destroy', '-f', resource[:name]])
        when :present
          iocage(['create', '-c', "tag=#{resource[:name]}"])
          if resource[:state] == :up
            pre_start_properties.each {|p|
              if resource[p]
                set_property(p.to_s, resource[p])
              end
            }
            iocage(['start', resource[:name]])
            if resource[:user_data]
              tmpfile = Tempfile.new('puppet-iocage')
              tmpfile.write(resource[:user_data])
              tmpfile.close
              execute("/usr/local/sbin/iocage exec #{resource[:name]} /bin/sh",
                { :stdinfile => tmpfile.path }
              )
              tmpfile.delete
            end
          end
        end
      end

      need_restart = false
      pre_start_properties.each {|p|
        if @property_flush[p]
          need_restart = true
          set_property(p.to_s, @property_flush[p])
        end
      }

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

      if need_restart
        restart
      end
    end
    @property_hash = resource.to_hash
  end
end
