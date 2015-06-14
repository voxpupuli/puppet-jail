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
end
