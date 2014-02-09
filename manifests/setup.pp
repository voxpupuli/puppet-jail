# Class: jail::setup
#
# Lay down the glpbal configuration for jail.conf as well as create the needed
# directories and/or zfs mountpoints.
#
class jail::setup (
  $usezfs    = false,
  $zpool     = 'zroot',
  $zfsname   = 'jails',
  $basedir   = '/jails',
  $interface = undef
) {

  if $usezfs {
    zfs { "${zpool}/${zfsname}":
      ensure     => present,
      mountpoint => $basedir,
    }
  } else {
    file { $basedir:
      ensure => directory,
      owner  => 'root',
      group  => '0',
      mode   => '0750',
    }
  }

  concat::fragment { 'jail.conf-header':
    order   => '00',
    content => template('jail/jail.conf-header.erb'),
    target  => '/etc/jail.conf',
  }

  concat { '/etc/jail.conf': }
}
