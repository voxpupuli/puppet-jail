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
        :provider => :iocage,
        :ensure => :present,
        :name => j[:tag],
        :state => j[:state],
        :boot => j[:boot],
      }

      if j[:jid] != '-'
        jail_properties[:jid] = j[:jid]
      end

      all_properties = get_jail_properties(j[:tag])

      extra_properties = [
          :ip4_addr,
          :ip6_addr,
          :hostname,
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

  def flush
    if @property_flush
      Puppet.debug @property_flush

      if @property_flush[:ensure]
        case resource[:ensure]
        when :absent
          iocage(['stop', resource[:name]])
          iocage(['destroy', '-f', resource[:name]])
        when :present
          iocage(['create', '-c', "tag=#{resource[:name]}"])
          if resource[:state] == :up
            iocage(['start', resource[:name]])
          end
        end
      end


      need_restart = false
      [:boot,:ip4_addr,:ip6_addr,:hostname].each {|p|
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
