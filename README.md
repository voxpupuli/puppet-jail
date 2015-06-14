# FreeBSD Jail management with Puppet

[![Build Status](https://travis-ci.org/xaque208/puppet-jail.svg?branch=master)](https://travis-ci.org/xaque208/puppet-jail)

A Puppet module for creating and destroy Jails on FreeBSD.

## Disclaimer

Its a bit rough around the edges, and I fully expect things to
change.

## Usage

### Setup

To use this module, you must declare a `jail::setup` with the defaults for the module on a given host.  I'm using something like the following for each of my jail hosts.


```Puppet
class { 'jail::setup':
  usezfs    => true,
  zpool     => 'zroot',
  interface => 'em0',
}
```

This allows the type to use the correct jail without having to
specify the pool on each jail.

### ZFS Backed Jails

ZFS jails are implemented using the underlying `jail` type and provider, but with a slim manifest wrapper to assist in actually creating and destroying the ZFS that houses the jail.

```Puppet
jail::zfsjail { 'ns1':
  ensure            => 'running',
  config            => {
    'host.hostname' => 'myhostname.example.com',
    'ip4.addr'      => '169.254.0.11',
    'ip6.addr'      => 'fc00::11',
  }
}
```

Jails can be in one of 4 states represented by the `ensure`
parameter.  These are 'running', 'stopped', 'present', and 'absent'.

