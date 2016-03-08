# Class: jail::setup
#
# Lay down the glpbal configuration for jail.conf as well as create the needed
# directories and/or zfs mountpoints.
#
class jail::setup () {

  package { 'iocage': ensure => installed; }
  service { 'iocage':
    ensure => 'running',
    enable => true,
  }

  file { '/etc/jail.conf':
    ensure => absent,
  }
}
