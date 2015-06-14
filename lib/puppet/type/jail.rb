# This type is meant to facilitate teh deployment of FreeBSD jails.
#
# We make assumptions.
#
# 1. The directorie that you are attemtping to deploy a jail to, actually exists.
#

Puppet::Type.newtype(:jail) do

  newparam(:name, :namevar => true) do
    desc "The name of the jail, and only the name"
  end

  newparam(:source) do
    desc "Full path to the local base file"
    isrequired
  end

  newparam(:jailbase) do
    desc "The base directory to build the jail. e.g. /jails"
    isrequired
  end

  ensurable do
    desc "what state should the jail be in"

    newvalue(:present, :event => :jail_created) do
      provider.create
    end

    newvalue(:absent, :event => :jail_destroyed) do
      provider.destroy
    end

    newvalue(:running, :event => :jail_started) do
      provider.start
    end

    newvalue(:stopped, :event => :jail_stopped) do
      provider.stop
    end
  end

  provide(:jail) do

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
end
