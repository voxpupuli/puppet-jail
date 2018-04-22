# Class: jail::setup
#
# Lay down the global configuration for jail.conf as well as create the needed
# directories and/or zfs mountpoints.
#
class jail::setup () {

  package { $jailmanager:
    ensure  => latest,
    require => File['/etc/jail.conf'],
  }

  service { $jailservice:
    enable  => true,
    require => [File['/etc/jail.conf'], Package[$jailmanager]],
  }

  file { '/etc/jail.conf':
    ensure => absent,
  }
}
