Puppet::Type.type(:jail).provide(:default) do

  confine :kernel    => :freebsd
  defaultfor :kernel => :freebsd

  desc "The jail provider is the only provider for the jail type."

  commands :jail    => "/usr/sbin/jail"
  commands :jls     => "/usr/sbin/jls"
  commands :jexec   => "/usr/sbin/jexec"
  commands :tar     => "/usr/bin/tar"
  commands :chflags => "/bin/chflags"

  def get_jails
    jaildata = jls(['-h'])
    debug jaildata.split(/\r?\n/).inspect
  end

  def exists?
    get_jails()
    path = "#{resource[:jailbase]}/#{resource[:name]}/root"
    debug path.inspect
    File.directory?(path)
  end

  def running?
    output = jls('-n', 'name').split("\n").find {|j| j =~ /name=#{resource[:name]}/ }
    debug output.inspect
    ! output.nil?
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
    create unless exists?
    jail(['-c', resource[:name]])
  end

  def stop
    jail(['-r', resource[:name]]) if running?
  end
end
