# jenkins Cookbook CHANGELOG

This file is used to list changes made in each version of the jenkins cookbook.

## 5.0.1 (2017-05-01)

- Add -remoting option that is required due to [Jenkins issue](https://jenkins.io/blog/2017/04/26/security-advisory/). Attribute `['jenkins']['executor']['protocol']` has been added to allow for using the deprecated remoting option (default) or ssh/http in which attribute `['jenkins']['executor']['cli_user']` needs to be assigned.

## [5.0.0](https://github.com/chef-cookbooks/jenkins/tree/v5.0.0) (2017-03-08)
[Full Changelog](https://github.com/chef-cookbooks/jenkins/compare/v4.2.1...v5.0.0)

**Improvements**
- Add support for 2.x ([daften](https://github.com/daften))
- Change default to stable, adding channel toggle [\#575](https://github.com/chef-cookbooks/jenkins/pull/575) ([cheeseplus](https://github.com/cheeseplus))
- Use `dpkg_autostart` to prevent service from starting post install
- Fix update-center.json URL
- Fix Jenkins home dir creation on Ubuntu for package installs [\#576](https://github.com/chef-cookbooks/jenkins/pull/576) ([cheeseplus](https://github.com/cheeseplus))
- Lots of testing and CI fixes

## 4.2.1 (2017-01-18)

- Fix the repo URL for RHEL based systems.

## 4.2.0 (2017-01-17)

- updated the jenkins url and keys for redhat in the attributes
- Remove superfluous call ensure_update_center_present to update center
- Allow overriding of maxopenfiles with a new attribute
- Require the latest compat_resource

## 4.1.2 (2016-11-03)

- Fix undefined java method

## 4.1.1 (2016-11-02)

- Fix issue #531

## 4.1.0 (2016-10-25)

- Add SSH retry attributes and testing to the slave_ssh resource
- Fix Issue #205 allow user groups of runit process owner

## 4.0.1 (2016-10-18)
- Fix NotImplementedError by removing the use of the Chef::Resource::RESOURCENAME

## 4.0.0 (2016-10-17)
- Changes how credentials are created, using the id rather than username to fix Issue #447

## 3.1.1 (2016-10-17)
- Fix implicit argument passing of super Issue #524
- Fix ECDSA check
- include_recipe instead of using recipe_eval in slave_jnlp library

## 3.1.0 (2016-10-07)

- Fix conversion of multiline string from Ruby to Groovy
- Check for the mailer plugin's availability
- Support ECDSA private keys in addition to RSA keys.
- add use_inline_resources and use action DSL helper in all providers

## 3.0.0 (2016-10-01)

- apt and yum cookbook dependencies have been replaced with compat_resource
- Base /etc/yum.conf and apt-get update are no longer provided by this cookbook. Both of these tasks were beyond the scope of this cookbook
- The Java recipe has been deprecated. Picking the right Java JDK is a complex task that depends not only on technical issues, but licensing requirements. The Java cookbook should be included in your wrapper cookbook so you can decide between openJDK and Oracle JDK
- The node name has been removed from all configs to make building AMIs or containers easier
- A new attribute has been added to configure file limits for the Java process. See the attributes file for details
- Add chef_version metadata
- Allow using Runit 2.0 cookbook by loosening the dependencies
- Replace node.set with node.normal to avoid deprecation warnings
- Remove the FQDN from the jenkins-slave template
- Add build matcher for jenkins_job
- Require Chef 12.1 not 12.0
- Add platform support to the metadata
- Add basic server testing in Travis CI with kitchen-dokken. More to come!

## v2.6.0 (2016-06-14)

- Clarify that this cookbook only supports Chef 12+
- Add the ability to specify jvm_options for executors
- Remove the pin of the apt cookbook in the metadata to the 2.X release
- Switch ruby linting to Cookstyle from Rubocop

## v2.5.0 (2016-05-12)

- Increased the required Runit cookbook to 1.7
- Added a new :build action to jenkins_job. See the readme for details
- Updated custom resource format to conform to best practices
- Added support for secret text credentials. See the readme for details
- JENKINS_USER and JENKINS_GROUP can now be set via attribute
- Changed remote directory resource to work with domain users in the windows slave resource
- Refactored user credentials code to new intermediate class
- Fixed the path to the jar cache in the jenkins slave .bat file
- Resolved warnings when using the windows slave resource
- Fixed bad documentation around remote file checksums
- Resolved failing Foodcritic warnings
- Added Chefspec matchers
- Added source_url and issues_url to the metdata for Supermarket
- Resolved Rubocop warnings
- Fixed a label typo in the serverspecs
- Added our standard contributing and testing docs
- Added a Rakefile for simplified testing
- Updated .gitignore and chefignore files to use the standard Chef varieties
- Added testing in Travis CI with docker

## v2.4.1 (2015-09-10)

### Bug

- Make slave_exe resource only get created if it is missing.

## v2.4.0 (2015-09-03)

### Bug

- Ensure Jenkins home directory has correct ownership after package installation
- Fix for NPE when creating already registered slave with env vars defined
- Fix ArgumentError when comparing two versions not of the same type
- Don't mutate value when converting to Groovy; Fixes #371

### Improvement

- Automatically add "Logon As A Service" right to Windows slaves
- Allow optional 'keyserver' attribute for apt
- Add a `MAINTAINERS` file

## v2.3.1 (2015-05-19)

### Bug

- Fix Travis badge
- Re-enable lazy attribute defaults in LWRP workaround for Chef 11
- Properly escape single quotes in Groovy code

### Improvement

- Download update center metadata every time

## v2.3.0 (2015-05-14)

### New Feature

- Add stable source support for package installation
- Add support for `jvm_options` on `slave_ssh` resource
- Support executing commands prior to launching Jenkins Windows slave
- Add username/password support to executor

### Improvement

- Remove EOL Ruby, update with current supported Rubies
- Update `.kitchen.yml`
- Use ChefDK for all Travis testing
- Fix all Rubocop 0.28.0 style errors
- Create system user and group for jnlp slave if `use_system_account` flag is set.
- `jenkins_plugin`: Do a better job understanding "latest" version
- Mark all credential resources as sensitive; Fixes #288
- Password credentials ID does not need to be a UUID
- Restart Windows service on failure; Fixes #334
- Re-install the Windows service if the winsw XML changes
- Properly restart the service if the slave jar is updated

### Bug

- Instantiate Windows-specific resource class; Fixes #336
- Need to escape the `\n` when there are multiple public keys.

## v2.2.2 (2015-01-15)

### Bug

- Gem::Version raising ArgumentError for weirdly versioned Jenkins plugins
- Force UTF-8 encoding when parsing update center JSON
- README grammar fixes

## v2.2.1 (2014-12-02)

### Bug

- Ensure Win service install command respects alternate service names

## v2.2.0 (2014-12-02)

### Bug

- Handle jobs that do not have a `disabled` attribute
- Remove unneeded service restart in Windows slaves
- Update Jenkins service check to use `WIN32OLE`
- Properly quote executor file paths cause $WINDOWS
- Properly escape backslashes in generated Groovy code
- Jenkins timeout shouldn't rescue Net::HTTP timeout
- Make sure Net::HTTP#use_ssl is turned on for https end-point
- Wrap converted Groovy strings in single quotes
- Recover from commands executed with unknown credentials. This should also fix some cases of JENKINS-22346.

### Improvement

- Use atomic updates when downloading the slave JAR
- Create the `slave.jar` in a slave's JENKINS_HOME
- Support a checksum attribute for `winsw.exe` download
- Support setting the `PATH` on Windows slave
- Add .NET 4.0 compat fix for `winsw`
- Restart services when `slave.jar` is updated
- Allow `jenkins_slave` to be used as a standalone resource
- Add attribute for configuring Runit sv_timeout on masters installed from war
- Add attribute for creating `jenkins` user as a system account
- Allow `Executor#execute!` to pass options to underlying `Shellout` instance.
- Set the senstive attribute for the jenkins cli private key file
- Don't backup plugins on uninstall
- Properly allow installation of specific versions of a plugin. Previously this only worked when a source URL was provided.
- Optionally ensure a plugin's dependencies are installed before proceeding with it's installation
- Handle plugin downgrades correctly (requires an uninstall of existing, newer version).

## v2.1.2 (2014-07-02)

- Fix a bug where `jenkins_windows_slave` was being called as `jenkins_jnlp_slave`

## v2.1.1 (2014-06-30)

- Use the update-center to install plugins and their dependencies
- Handle `super` calls correctly in `load_current_resource`
- Backport Chef patches to temporary libraries
- Default `Slave#environment` to `nil` instead of `{}`
- Fix a bug where `super` was called in DSL methods

## v2.1.0 (2014-06-26)

- Change Jenkins command prefix to use the slave object
- Escape data given to the executor
- Always read plugin manifest files as UTF
- Typo: Shelllwords -> Shellwords
- Upgrade to Berkshelf 3
- Add ChefSpec tests for recipes
- Add Jenkins::Executor tests
- Bug: Use ::File instead of File
- Remove foodcritic
- Fix Rubocop warnings
- Only create user, group and directories on war installations
- Only create supporting resources on JNLP slaves
- Split `jnlp` and `ssh` slave fixtures
- Document that SSH slaves should be created on the master
- Ensure compiled attributes respect overrides
- Ensure plugin installs respect global mirror setting
- Add fallback to `jenkins_slave` matcher if authn is enabled
- Update authn int tests to load private key from data bag item
- Add integration test coverage for smoke tests
- Add support for listening on a specific address
- Allow user to specify the password
- Use a temporary file to run groovy scripts
- Use executor['timeout'] for timeout in ShellOut in executor.execute!
- Give timeout a default value (60) in the executor
- Ignore Errno::ENETUNREACH until timeout
- Fix a bug in default windows domain name
- Update winsw version to 1.16
- Upgrade to ChefSpec 4 and fix CI
- Use the run_state to store sensitive information
- Switch to LWHRPS for everything
- Handle nil values in credentials comparison
- Add ChefSpec matchers for all LWRPs
- Don't automatically restart after plugin installation
- Add the ability to pass in a list of additional options in `jenkins_plugin`
- Specify actions and default_action in inherited resources

## v2.0.2 (2014-01-30)

- Add support for prefix and suffix commands on SSH nodes
- Don't commit documentation into git
- Fix YARD-generated documentation
- Fix plugin output parsing
- Accept a 403 response, indicating the server is "ready"
- Use a custom URI joining method
- Document the need for the Jenkins credentials plugin
- Fix a typo in the slave jar URL
- Fix typos in README
- Fix grammar in the Jenkins helper error
- Update Rubocop

## v2.0.0 (2014-01-14)

**This is a major refactor of the Jenkins cookbook and is not backwards-compatible.**

- Updated to the latest gems
- Added a full Test Kitchen integration suite for every resource
- Added Rubocop + Foodcritic + Travis
- Updated contributing guidelines
- Updated issue reporting guidelines
- Refactored README format - attribute documentation is now inline. Please see the specific attribute file for documentation, rather than a verbose README
- Added a Rakefile for encapsulating commands
- Move testing instructions into contribution guidelines
- Remove old TODO file
- Refactor attributes into semantic groupings and namespaces

  - `jenkins.cli` has been removed
  - `jenkins.java_home` has been changed to `jenkins.java` and accepts the full path to the java binary, not the JAVA_HOME
  - `jenkins.iptables_allow` has been removed
  - `jenkins.mirror` -> `jenkins.master.mirror`
  - `jenkins.executor` created
  - `jenkins.executor.timeout` created
  - `jenkins.executor.private_key` created
  - `jenkins.executor.proxy` created
  - `jenkins.master` created and only refers to the Jenkins master installation
  - `jenkins.master.source` created to refer to the full URL of the war download
  - `jenkins.master.jvm_options` created
  - `jenkins.master.jenkins_args` added
  - `jenkins.master.url` -> `jenkins.master.endpoint`
  - `jenkins.master.log_directory` created
  - `jenkins.node` attributes have all been removed
  - `jenkins.server` attributes have all been removed

- Removed Chef MiniTest handler

- Created a new executor class for running commands through the CLI

- Create `jenkins_command` resource for executing arbitrary commands against the Jenkins CLI

- Create `jenkins_script` resource for executing arbitrary groovy scripts agains the Jenkins CLI

- Create `jenkins_credentials` resource for creating and managing Jenkins credentials

- Refactor `jenkins_job` resource for creating and managing jobs

- Refactor `jenkins_plugin` resource for creating and managing plugins

- Create `jenkins_slave` (and sub-resources) for managing Jenkins slaves (formerly called "nodes")

- Add `jenkins_user` resource for creating and managing users

- Remove dependencies on java, apache2, nginx, and iptables

- Remove `jenkins_cli` resource (it's been replaced by `jenkins_command`)

- Remove `jenkins_execute` resource (it's been replaced by `jenkins_command`)

- Remove the pesky "block_until_operational" Ruby block

- Remove `jenkins_node` resource (it's now a series of `jenkins_slave` resources)

- Don't pin plugins (users should explictly provide a version to ensure pinning)

- Upgrade apt and yum dependencies

- Allow full customization of the war file download URL

- Remove apache2 proxy, nginx proxy, and iptables support; they are outside the scope of this cookbook and add unnecessary complication

- Default recipe has been removed

- Iptables recipe has been removed

- Added a _very_ basic Java recipe with caveats

- Added a Jenkins master recipe (formerly called "server")

- Removed "node" recipes - they have all been replaced by HWRPs

- Removed proxy recipes

- Updated Debian and RedHat templates to the latest version

- Added the ability to add authentication

- Added custom ServerSpec matchers

- "node" renamed to "slave"

- "server" renamed to "master"

## v1.2.2

### Bug

- **[COOK-3742](https://tickets.chef.io/browse/COOK-3742)** - Remove trailing comma (restores compatability with Ruby 1.8)

## v1.2.0

### Improvement

- **[COOK-3710](https://tickets.chef.io/browse/COOK-3710)** - Allow winsw url to be changed with a node attribute

### Bug

- **[COOK-3709](https://tickets.chef.io/browse/COOK-3709)** - Use correct attribute value for `java_home`
- **[COOK-3701](https://tickets.chef.io/browse/COOK-3701)** - Fix a refactor bug where a template variable was removed that was used in a nested template
- **[COOK-3594](https://tickets.chef.io/browse/COOK-3594)** - Fix MiniTest Chef Handler tests for directory permissions

## v1.1.0

### Bug

- **[COOK-3683](https://tickets.chef.io/browse/COOK-3683)** - Fix plugin provider failures finding the current plugin version
- **[COOK-3667](https://tickets.chef.io/browse/COOK-3667)** - Unbreak Travis-CI integration
- **[COOK-3623](https://tickets.chef.io/browse/COOK-3623)** - Fix issue where plugins were never updated even if you bump the plugin version in attributes
- **[COOK-3620](https://tickets.chef.io/browse/COOK-3620)** - Fix Jenkins `_node_jnlp_test.rb` assumptions
- **[COOK-3517](https://tickets.chef.io/browse/COOK-3517)** - Various bug fixes for `jenkins::windows`
- **[COOK-3516](https://tickets.chef.io/browse/COOK-3516)** - Fix Jenkins slaves that use JNLP when Jenkins has security enabled

### New Feature

- **[COOK-3619](https://tickets.chef.io/browse/COOK-3619)** - Support intermediate SSL certificates

### Improvement

- **[COOK-3587](https://tickets.chef.io/browse/COOK-3587)** - Adding minitest-handler to the runlist for the node suite in Jenkins cookbook

## v1.0.0

- Initial Chef Software release

## v0.7.0

- Initial import from Heavywater upstream: <https://github.com/heavywater/chef-jenkins>
