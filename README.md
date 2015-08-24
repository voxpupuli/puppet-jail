# FreeBSD Jail management with Puppet

[![Build Status](https://travis-ci.org/xaque208/puppet-jail.svg?branch=master)](https://travis-ci.org/xaque208/puppet-jail)

Manage FreeBSD jails with Puppet, leveraging [iocage] for jail management.

### Setup

This module expects to be the only jail manager on a given system.  Each system where jails will be managed needs to include the `jail::setup` class as well.

```Puppet
include jail::setup
```

This simply installs 'iocage' and removes '/etc/jail.conf'.

This allows the type to use the correct jail without having to
specify the pool on each jail.

### A simple jail

```Puppet
jail { 'myjail1':
  ensure   => present,
  state    => 'up',
  ip4_addr => 'em0|10.0.0.10/24',
  ip6_addr => 'em0|fc00::10/64',
  hostname => 'myjail1.example.com',
  boot     => 'on'
}
```

Note the `ip4_addr` and the `ip6_addr` properties take an interface name and an IP address seperated by a pipe character.  This value is passed directly to `iocage(8)`.  You may wish to read the man page.

[iocage]: http://iocage.readthedocs.org/en/latest/

