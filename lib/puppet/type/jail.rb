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
    desc "deprecated: Full path to the local base file"
  end

  newparam(:jailbase) do
    desc "deprecated: The base directory to build the jail. e.g. /jails"
  end

  newparam(:state) do
    desc "Either running or stopped"

    newvalues(:up) do
      provider.start
    end

    newvalues(:down) do
      provider.stop
    end
  end

  ensurable do
    desc "what state should the jail be in"

    newvalues(:present) do
      provider.create
    end

    newvalues(:absent) do
      provider.destroy
    end

    aliasvalue(:running, :present)
    defaultto :present
  end


  newproperty(:jid) do
    desc "The jail ID for running jails"
  end

  jail_params = [
  ]

  jail_params.each {|p|
    newparam(p.to_sym)
  }
end
