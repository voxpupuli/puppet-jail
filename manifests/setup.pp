# Class: jail::setup
#
# Lay down the global configuration for jail.conf as well as create the needed
# directories and/or zfs mountpoints.
#
class jail::setup () {

  package { 'iocage':
    ensure => installed;
  }

  service { 'iocage':
    enable => true;
  }

  file { '/etc/jail.conf':
    ensure => absent;
  }

  File['/etc/jail.conf'] ~> Service['iocage']
  Package['iocage'] ~> Service['iocage']
}
