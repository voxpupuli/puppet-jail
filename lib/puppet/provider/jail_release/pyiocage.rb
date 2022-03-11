# frozen_string_literal: true

Puppet::Type.type(:jail_release).provide(:pyiocage) do
  desc 'Manage jails release base downloads using iocage(8)'
  confine    kernel: :freebsd
  defaultfor kernel: :freebsd

  # this is used for further confinement
  commands pyiocage: '/usr/local/bin/iocage'

  def self.iocage(*args)
    cmd = ['/usr/local/bin/iocage', args].flatten.join(' ')
    execute(cmd, override_locale: false, failonfail: true, combine: true)
  end

  def iocage(*args)
    self.class.iocage(args)
  end

  mk_resource_methods

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov
      end
    end
  end

  def self.instances
    releases = iocage('list', '-Hr')
    releases.split("\n").map { |r| new(name: r, ensure: :present) }
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    iocage('fetch', '--release', resource[:name])
  end

  def destroy
    iocage('destroy', '--force', '--release', resource[:name])
  end
end
