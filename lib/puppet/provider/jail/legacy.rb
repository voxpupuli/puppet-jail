Puppet::Type.type(:jail).provide(:legacy) do

  desc "The deafult provider for the jail type.

  Extracts a tarball into the root of a given jail.  Manages stopping,
  starting, and destruction of a given jail."

  confine    :kernel => :freebsd

  desc "The jail provider is the only provider for the jail type."

  commands :jail    => "/usr/sbin/jail"
  commands :jls     => "/usr/sbin/jls"
  commands :jexec   => "/usr/sbin/jexec"
  commands :tar     => "/usr/bin/tar"
  commands :chflags => "/bin/chflags"

  mk_resource_methods

  def self.jail_hash
    begin
      output_lines = jls(['-h']).split("\n")
    rescue => e
      Puppet.debug "#jail_hash had an error -> #{e.inspect}"
    end

    headers = output_lines.shift.split
    data = []

    output_lines.each {|l|
      line_hash = {}
      fields = l.split
      headers.each_with_index {|h,i|
        line_hash[headers[i]] = fields[i]
      }
      data << line_hash
    }
    data
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def self.instances
    jail_hash.collect do |j|
      jail_properties = {
        :ensure => :running,
        :provider => :default,
        :name => j['name'],
        :jailbase => j['path'],
      }
      new(jail_properties)
    end
  end

  def exists?
    path = "#{resource[:jailbase]}/#{resource[:name]}"
    [:present,:running].include?(@property_hash[:ensure]) or File.directory?(path)
  end

  def running?
    [:running].include?(@property_hash[:ensure])
  end

  def create
    jaildir = resource[:jailbase] + '/' + resource[:name]
    debug " #{jaildir} "
    Dir.mkdir(jaildir) unless File.directory?(resource[:jailbase] + '/' + resource[:name])
    tar([ '-xpf', resource[:source], '-C', jaildir ])
  end

  def destroy
    jaildir = resource[:jailbase] + '/' + resource[:name]
    stop if running?
    chflags(['-R', 'noschg', jaildir])
    FileUtils.rm_rf(resource[:name])
  end

  def start
    Puppet.debug "What the fuck #{@property_hash}"
    create unless exists?
    jail(['-c', resource[:name]]) unless running?
  end

  def stop
    jail(['-r', resource[:name]]) if running?
  end
end
