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

  newparam(:jid) do
    desc "The jail ID for running jails"
  end


  ensurable do
    desc "what state should the jail be in"

    newvalues(:present) do
      provider.create
    end

    newvalues(:absent) do
      provider.destroy
    end

    defaultto :present
  end

  newproperty(:state) do
    desc "Either running or stopped"

    newvalues(:up) do
      provider.start
    end

    newvalues(:down) do
      provider.stop
    end
  end
end
