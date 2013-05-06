Puppet::Type.newtype(:jail) do
  ensurable

  newparam(:name, :namevar => true) do
    desc "Fully qualified path to jail"
  end

  newparam(:source) do
    desc "Where the base.txz is located"
    isrequired
  end

  #newparam(:zfs) do
  #  defaultto 'true'
  #end

  #newparam(:zfsquota) do
  #  defaultto '2G'
  #end

  provide(:jail) do

    confine :kernel    => :freebsd
    defaultfor :kernel => :freebsd

    desc "The jail provider is the only provider for the jail type."

    commands :jail    => "/usr/sbin/jail"
    commands :jexec   => "/usr/sbin/jexec"
    commands :tar     => "/usr/bin/tar"
    commands :chflags => "/bin/chflags"

    def exists?
      File.exists?(resource[:name])
    end

    def create
      Dir.mkdir(resource[:name])
      tar(['-xpf', resource[:source], '-C', resource[:name]])
    end

    def destroy
      chflags(['-R', 'noschg', resource[:name]])
      FileUtils.rm_rf(resource[:name])
    end

  end

end
