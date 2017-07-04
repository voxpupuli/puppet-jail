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
* `fstab` entries
* properties (except when template related!)
* `state` (either `iocage start` xor `iocage stop`)
* `type` (a template jail *cannot* run.)

any changes to the following parameters must trigger a rebuild:

* `template`
* `release`
* `ensure` (`absent` causes destruction)
* `user_data` (our jails are immutable, so any mutation to them causes a
  rebuild)


# Mapping to puppet

First and foremost, we should consider switching
to [`--name`](https://github.com/iocage/iocage/issues/244) as `namevar` instead
of using `tag=`.

Next, we should generalize the handling of non-essential (anything not retrieved
via `iocage list -l`)properties, by passing them in the properties hash.

Given the nature of certain parameters (the ones that trigger a reload, or a
rebuild), we should add an option which control whether a jail should be
restarted, or rebuilt by puppet.

Finally, if we want to continue using flush, we need to find a way to funnel
these four essential operations, create, update, rebuild, destroy — in an
idempotent manner.

# (Backwards) Compatibility

All these contemplation on design raise two questions:

- (how) do we keep backwards compatibility with the old module
- (how) do we bridge the gap between iocage_legacy and py3-iocage?
