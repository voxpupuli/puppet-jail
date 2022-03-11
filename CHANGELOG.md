# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v5.0.1](https://github.com/voxpupuli/puppet-jail/tree/v5.0.1) (2022-03-11)

[Full Changelog](https://github.com/voxpupuli/puppet-jail/compare/v5.0.0...v5.0.1)

**Breaking changes:**

- Drop support for FreeBSD 10, 11 \(EOL\) [\#62](https://github.com/voxpupuli/puppet-jail/pull/62) ([smortex](https://github.com/smortex))

**Merged pull requests:**

- puppetlabs/concat: Fix version range in metadata.json [\#65](https://github.com/voxpupuli/puppet-jail/pull/65) ([bastelfreak](https://github.com/bastelfreak))
- cleanup old hiera-in-modules setup [\#64](https://github.com/voxpupuli/puppet-jail/pull/64) ([bastelfreak](https://github.com/bastelfreak))
- modulesync 5.2.0 / package\_name: Add `String[1]` datatype [\#63](https://github.com/voxpupuli/puppet-jail/pull/63) ([bastelfreak](https://github.com/bastelfreak))

## [v5.0.0](https://github.com/voxpupuli/puppet-jail/tree/v5.0.0) (2021-06-15)

[Full Changelog](https://github.com/voxpupuli/puppet-jail/compare/4.0.1...v5.0.0)

**Breaking changes:**

- Drop EoL Puppet 5 support; Add Puppet 7 [\#57](https://github.com/voxpupuli/puppet-jail/pull/57) ([bastelfreak](https://github.com/bastelfreak))

**Implemented enhancements:**

- Add FreeBSD 11-13 support [\#54](https://github.com/voxpupuli/puppet-jail/pull/54) ([bastelfreak](https://github.com/bastelfreak))

**Merged pull requests:**

- puppetlabs/concat: Allow latest releases [\#58](https://github.com/voxpupuli/puppet-jail/pull/58) ([bastelfreak](https://github.com/bastelfreak))
- cleanup metadata.json + README.md / add missing LICENSE file [\#55](https://github.com/voxpupuli/puppet-jail/pull/55) ([bastelfreak](https://github.com/bastelfreak))
- Drop Puppet 4, add Puppet 5 and 6 [\#53](https://github.com/voxpupuli/puppet-jail/pull/53) ([ekohl](https://github.com/ekohl))
- modulesync 3.0.0 & puppet-lint updates [\#50](https://github.com/voxpupuli/puppet-jail/pull/50) ([bastelfreak](https://github.com/bastelfreak))
- Set the property only if required [\#47](https://github.com/voxpupuli/puppet-jail/pull/47) ([xaque208](https://github.com/xaque208))
- Update from xaque208 modulesync\_config [\#46](https://github.com/voxpupuli/puppet-jail/pull/46) ([xaque208](https://github.com/xaque208))

## [4.0.1](https://github.com/voxpupuli/puppet-jail/tree/4.0.1) (2019-03-26)
#### Summary
A significant update to the module.  Please see the readme for change details.

 - Modulesync for deployment updates
 - Add design doc for where to keep the conversation about approach
 - Replace iocage.sh provider with iocage.py provider
 - Moved iocage.sh provider to iocage_legacy name
 - Add new properties

## 2016-08-29 3.1.0
#### Summary
Drop old puppet versions, add tests for existing functionality.

## 2016-07-27 3.0.0
#### Summary
Drop legacy code and add new zfs properties.

## Features
 - Add ZFS properties
 - Drop legacy jail provider

## 2016-05-31 2.1.1
#### Summary
Changes to testing dependencies.

#### Testing
 - Drop guard from the Gemfile

A feature release.
## 2016-05-31 2.1.0
#### Summary
A feature release.

#### Features
 - Add user_data support for first boot script

## 2016-04-25 2.0.9
### Summary
This release adds a changelog.

#### Features
 - Add a changelog

## 2016-04-22 2.0.8
### Summary
This is a bugfix release.

#### Bugfixes
 - Handl the order of the iocage service and package correctly

## 2016-04-04 2.0.7
### Summary
This is a testing release.

#### Testing
 - Update tests to include puppet4

## 2016-03-08 2.0.6
### Summary
This is a bugfix release to avoid starting the iocage service.

#### Bugfixes
 - Only enable the service as there is no daemon

## 2016-03-08 2.0.5
### Summary
This is a feature release to include iocage service management.

#### Features
 - Manage the iocage service

## 2016-02-21 2.0.4
### Summary
This is a bugfix release.

#### Bugfixes
 - Fix regex match more complex hostnames and add test

## 2015-11-28 2.0.3
### Summary
This is a bugfix release to address property handling.

#### Bugfixes
 - Set jail properties upon creation before boot

## 2015-10-19 2.0.2
### Summary
This is a bugfix release.

#### Bugfixes
 - Fix regex to include JIDs that begin with '1' and add test

## 2015-09-08 2.0.1
### Summary
This is a bugfix release.

#### Bugfixes
 - Add regex matching for discovering only iocage created jails
 - Fix boot parameter in documentation

## 2015-08-16 2.0.0
### Summary
This is a backwards incompatible release to support a new jail management
utility framework called iocage(8).

#### Features
 - Add new provider for iocage with basic tests
 - Adjust type parameters to match iocage nomenclature

## 2015-08-16 1.0.0
### Summary
This release is the first major release of the jail module, containing a
minimal pattern of creating ZFS based jails using a puppet type and provider.

#### Features
- Initial type and provider for managing ZFS based jails



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
