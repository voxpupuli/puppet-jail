# FreeBSD Jail management with Puppet

[![CI](https://github.com/voxpupuli/puppet-jail/actions/workflows/ci.yml/badge.svg)](https://github.com/voxpupuli/puppet-jail/actions/workflows/ci.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/jail.svg)](https://forge.puppetlabs.com/puppet/jail)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/jail.svg)](https://forge.puppetlabs.com/puppet/jail)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/jail.svg)](https://forge.puppetlabs.com/puppet/jail)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/jail.svg)](https://forge.puppetlabs.com/puppet/jail)
[![Apache-2 License](https://img.shields.io/github/license/voxpupuli/puppet-jail.svg)](LICENSE)

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
  ensure    => present,
  state     => 'up',
  ip4_addr  => 'em0|10.0.0.10/24',
  ip6_addr  => 'em0|fc00::10/64',
  hostname  => 'myjail1.example.com',
  boot      => 'on',
  user_data => template('mysite/user_data.sh.erb'),
}
```

Note the `ip4_addr` and the `ip6_addr` properties take an interface name and an IP address separated by a pipe character.  This value is passed directly to `iocage(7)`.  You may wish to read the man page.

[iocage]: http://iocage.readthedocs.org/en/latest/

