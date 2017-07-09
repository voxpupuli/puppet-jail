# This type is meant to facilitate the deployment of FreeBSD jails by fetching a
# FreeBSD base for different releases.

Puppet::Type.newtype(:jail_release) do
  ensurable

  newparam(:name, namevar: true) do
    desc 'The release to fetch'
  end
end
