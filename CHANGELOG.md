## Unreleased

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

