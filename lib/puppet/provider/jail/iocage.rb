Puppet::Type.type(:jail).provide(:iocage) do

  desc "Manage jails using iocage(8)"
  confine    :kernel => :freebsd
  defaultfor :kernel => :freebsd

  command :iocage => '/usr/local/sbin/iocage'

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
        :ensure => :present,
        :provider => :iocage,
        :state => j[:state],
        :name => j[:tag],
      }
      new(jail_properties)
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def running?
    ['up'].include?(@property_hash[:state])
  end

  def create
    iocage(['create', '-c', "tag=#{resource[:name]}"])
  end

  def destroy
    iocage(['destroy', '-f', resource[:name]])
  end

  def start
    iocage(['start', resource[:name]])
  end

  def stop
    iocage(['stop', resource[:name]])
  end

end
