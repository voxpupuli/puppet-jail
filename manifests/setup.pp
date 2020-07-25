# Class: jail::setup
#
# Lay down the global configuration for jail.conf as well as create the needed
# directories and/or zfs mountpoints.
#
class jail::setup (
  $package_name = 'py36-iocage'
) {
  package { 'iocage':
    ensure => installed,
    name   => $package_name,
  }

  service { 'iocage':
    enable => true,
  }

  file { '/etc/jail.conf':
    ensure => absent,
  }

  File['/etc/jail.conf'] ~> Service['iocage']
  Package['iocage'] ~> Service['iocage']
}
