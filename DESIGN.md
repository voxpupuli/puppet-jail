# Design of this Module

This module's primary provider is `iocage`, as such it maps relatively directly
to its semantics. However, it can be tricky to map these back to puppet. When
putting idempotency into consideration, it gets a bit trickier.

In this document we'll consider how Create-Update-Delete works, and what it affects.

The core of our design is that the `tag=` is unique (`namevar`). We must do
anything to ensure that. 

## Create

If a jail (or template) does not exist, `create` will create it. This maps to
`iocage create`. Plenty of properties can be passed on the same command-line.

## Destroy

If a jail (or template) exists, it must first be stopped (`iocage stop`), and
can then be destroyed (`iocage destroy -f`).

With the easy ones out of the way, let's look at

## Update

any changes to the following parameters must trigger a reload (`iocage stop`
followed by `iocage start`)

* `ip4_addr` or `ip6_addr`
* fstab entries
* properties (except when template related!)
* state (either `iocage start` xor `iocage stop`)
* type (a template jail *cannot* run.)

any changes to the following parameters must trigger a rebuild:

* template
* release
* ensure (`absent` causes destruction)


# Mapping to puppet
