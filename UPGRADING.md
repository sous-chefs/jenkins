# Upgrading

## (9.0.0) Runit to Systemd conversion

Version 9.0.0 of this cookbook replaced the Runit services for WAR installation and JNLP slaves with Systemd services.
This replacement is done mostly automatically, but some manual cleanup is needed to completely remove Runit.

What is done automatically:

- stop / disable the old runit service
- remove the old service files in `/etc/service` and `/etc/init.d`
- create / start / enable the new systemd service

What needs to be done manually:

- stop / disable runit manager service (`runit` / `runsvdir-start`)
- uninstall runit
