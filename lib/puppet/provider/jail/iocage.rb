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
      }

      if j[:jid] != '-'
        jail_properties[:jid] = j[:jid]
      end

      new(jail_properties)
    end
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
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

  def state=(value)
    @property_flush[:state] = value
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

      if @property_flush[:state]
        case resource[:state]
        when :up
          iocage(['start', resource[:name]])
        when :down
          iocage(['stop', resource[:name]])
        end
      end
    end
    @property_hash = resource.to_hash
  end
end
