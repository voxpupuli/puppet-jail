# This type is meant to facilitate the deployment of FreeBSD jails.
#

Puppet::Type.newtype(:jail) do
  ensurable

  newproperty(:jid) do
    desc <<-EOM
         The jail ID for running jails

         This is a read-only property.
    EOM
  end

  # for py3-iocage, this can be uuid & hostname
  newparam(:name, namevar: true) do
    desc 'The name (and hostname) of the jail'
  end

  newproperty(:boot) do
    desc 'Either on or off'
    newvalues(:on, :off)
  end

  newproperty(:state) do
    desc 'Either running or stopped'
    newvalues(:up, :down)
  end

  newproperty(:type) do
    desc <<-EOM
         Type of jail. This can be `jail`, `basejail`, or `template`

         Changes to this property will lead to destruction and rebuild of the jail.
    EOM

    newvalues(:jail, :basejail, :template)
    defaultto(:jail)
  end

  newproperty(:release) do
    desc <<-EOM
         FreeBSD release of this jail. `EMPTY` if this is a Linux jail. `release` and `template` are mutually exclusive.

         Changes to this property will lead to destruction and rebuild of the jail.
    EOM
  end

  newproperty(:ip4_addr) do
    desc <<-EOM
         Interface|Address[,Interface|Address[...]]

         Changes to this property will cause a restart of the jail.
    EOM
  end

  newproperty(:ip6_addr) do
    desc <<-EOM
         Interface|Address[,Interface|Address[...]]

         Changes to this property will cause a restart of the jail.
    EOM
  end

  newproperty(:template) do
    desc <<-EOM
         Template jail to base this one off. `release` and `template` are mutually exclusive.

         Changes to this property will lead to destruction and rebuild of the jail.
    EOM
  end

  newparam(:allow_restart) do
    desc 'Allow restarting of this jail'
    newvalues(:true, :false)
    defaultto(:true)
  end

  newparam(:allow_rebuild) do
    desc 'Allow destroying! and rebuilding of this jail'
    newvalues(:true, :false)
    defaultto(:true)
  end

  newparam(:user_data) do
    desc <<-EOM
         Rendered content to pipe to a jailed shell upon creation

         Changes to this property will lead to destruction and rebuild of the jail.
    EOM
  end

  newparam(:pkglist, array_matching: :all) do
    desc 'A list of packages to be installed in this jail before startup'
    def insync?(is)
      Array(is).sort == Array(@shouldA).sort
    end
  end

  newproperty(:fstab, array_matching: :all) do
    desc 'A list of fstab entries for this jail to be mounted into. By default these are nullfs mounts.'
  end

  newproperty(:properties) do
    desc 'All properties (that deviate from the default)'
  end

  # global validation rules
  validate do
    raise ArgumentError, 'Templates cannot be set to start on boot!' if self[:boot] == :on && self[:type] == :template
    raise ArgumentError, 'Templates cannot be set to started!' if self[:state] == :up && self[:type] == :template
    raise ArgumentError, 'pkglist will need an IP address!' if !self[:pkglist].nil? && self[:ip4_addr].nil? && self[:ip6_addr].nil?
    raise ArgumentError, 'Cannot set both, `template` and `release` at the same time!' if self[:release] && self[:template]
  end

  def refresh
    if @parameters[:state] == :up
      provider.restart
    else
      debug 'Skipping restart: jail not running'
    end
  end
end
