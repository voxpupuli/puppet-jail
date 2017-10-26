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
    newvalues(%r{^[a-zA-Z0-9_-]+$})
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
         FreeBSD release of this jail. `EMPTY` if this is a Linux jail.  `release` and `template` are mutually exclusive.

         Changes to this property will lead to destruction and rebuild of the jail.
    EOM

    validate do |value|
      raise "Release must be a string, not '#{value.class}'" unless value.is_a?(String)
    end

    # iocage list -l will report release *with* the -patch level, but iocage
    # fetch expects it *without* the patch level.
    #
    # this is how we deal with that:
    def insync?(is)
      should = @should.is_a?(Array) ? @should.first : @should
      is.start_with?(should)
    end
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
    # TODO: add validation here
  end

  newproperty(:properties) do
    desc 'All properties (that deviate from the default)'
  end

  # global validation rules
  if Puppet.run_mode.master?
    validate do
      raise ArgumentError, 'Templates cannot be set to start on boot!' if self[:boot] == :on && self[:type] == :template
      raise ArgumentError, 'Templates cannot be set to started!' if self[:state] == :up && self[:type] == :template
      raise ArgumentError, 'Templates cannot have `fstab` entries!' if !self[:fstab].nil? && self[:type] == :template
      raise ArgumentError, 'pkglist will need an IP address!' if !self[:pkglist].nil? && self[:ip4_addr].nil? && self[:ip6_addr].nil?
      raise ArgumentError, 'Cannot set both, `template` and `release` at the same time!' if self[:release] && self[:template]
      raise ArgumentError, 'Must supply either `template` or `release`!' if !self[:release] && !self[:template]
    end
  end

  # `jail { x: release => foo }` should depend on jail_release { foo: }
  autorequire(:jail_release) do
    self[:release] if self[:release]
  end

  # `jail { x: template => foo }` should depend on jail { foo: template => yes }
  autorequire(:jail) do
    self[:template] if self[:template]
  end

  def refresh
    if @parameters[:state] == :up
      provider.restart
    else
      debug 'Skipping restart: jail not running'
    end
  end
end
