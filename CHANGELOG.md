# vagrant-lifecycle Changelog

## 0.1.6

Changed event hooks in order to make the plugin compatible with othe plugins such as [vagrant-managed-servers](https://github.com/tknerr/vagrant-managed-servers).

## 0.1.5

Fix broken evaluation of specified machines in the command line.

## 0.1.4

Changed Vagrant action the plugin hooks to so it can be used together with vagrant-databags plugin (with guaranteed 
order of execution).

## 0.1.3

Added support for Chef Zero and Chef Client provisioners.

## 0.1.2

Added middleware environment `:lifecycle_event` key for usage with other plugins.

## 0.1.1

Code cleanup. Added missing vagrant command synopsis.

## 0.1.0

Initial release.
