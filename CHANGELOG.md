jenkins Cookbook CHANGELOG
==========================
This file is used to list changes made in each version of the jenkins cookbook.

v1.0.1
------
- [COOK-3727] - Jenkins minitests not passing
- Enforce directory permissions for the home_dir, plugins_dir, ssh_dir and log_dir.
- Make directory permissions an attribute
- If you're installing package this will modify your directories permissions from the ones set by the package.

v1.0.0
------

- Initial Opscode release

v0.7.0
------

- Initial import from Heavywater upstream: https://github.com/heavywater/chef-jenkins
