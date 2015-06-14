# A rapper define to create a ZFS jail
#
# * Creates a ZFS for the jail
# * Extracts the base into the jail root
# * Drops the configuration for the jail
# * Starts the jail if requested
#
define jail::zfsjail (
  $source,
  $ensure             = present, # running, stopped, absent
  $config             = {},
  $bootstrap          = true,
  $bootstrap_template = 'jail/bootstrap.sh.erb',
){

  unless defined(Class['jail::setup']) {
    fail('Please use jail::setup before creating jails')
  }

  $pool    = $jail::setup::zpool
  $zfsname = $jail::setup::zfsname
  $basedir = $jail::setup::basedir

  if $ensure == present or $ensure == running or $ensure == stopped {
    concat::fragment { "jail.conf-${name}":
      target  => '/etc/jail.conf',
      content => template('jail/jail.conf-jail.erb'),
      before  => Jail[$name],
      notify  => Jail[$name],
    }

    zfs { "${pool}/${zfsname}/${name}":
      ensure => present,
      before => Jail[$name],
    }

    file { "${basedir}/${name}/etc/resolv.conf":
      ensure  => 'present',
      owner   => 'root',
      group   => '0',
      mode    => '0644',
      source  => '/etc/resolv.conf',
      replace => false,
      require => Jail[$name],
    }

    if $bootstrap {
      file { "${basedir}/${name}/tmp/bootstrap.sh":
        owner   => 'root',
        group   => '0',
        mode    => '0700',
        content => template($bootstrap_template),
        require => Jail[$name],
      }
    }
    Jail[$name] {
      require => Concat['/etc/jail.conf']
    }
  } elsif $ensure == absent {
    mount { "${basedir}/${name}/dev":
      ensure => absent,
      device => 'devfs',
      before => Zfs["${pool}/${zfsname}/${name}"],
    }

    zfs { "${pool}/${zfsname}/${name}":
      ensure  => absent,
      require => Jail[$name],
    }
    Jail[$name] {
      before => Concat['/etc/jail.conf']
    }
  }

  jail { $name:
    ensure   => $ensure,
    jailbase => $basedir,
    source   => $source,
  }
}
