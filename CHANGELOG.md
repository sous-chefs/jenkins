# jenkins Cookbook CHANGELOG

This file is used to list changes made in each version of the jenkins cookbook.

## Unreleased

Standardise files with files in sous-chefs/repo-management

## 9.6.1 - *2025-09-04*

- Cookstyle fixes

## 9.6.0 - *2025-03-17*

- Create `jenkins_githubapp_credentials` resource for creating and managing GitHub app Jenkins credentials
- Fix `jenkins_slave_jnlp` by evaluating `slave_jar_url` correctly
- Remove runit services before starting new service

## 9.5.23 - *2024-11-18*

Standardise files with files in sous-chefs/repo-management

Standardise files with files in sous-chefs/repo-management

## 9.5.22 - *2024-07-15*

Standardise files with files in sous-chefs/repo-management

Standardise files with files in sous-chefs/repo-management

Standardise files with files in sous-chefs/repo-management

## 9.5.21 - *2024-05-02*

## 9.5.20 - *2024-05-02*

## 9.5.19 - *2023-10-03*

Update Jenkins apt/rpm repository key urls.

## 9.5.18 - *2023-09-28*

## 9.5.17 - *2023-09-28*

## 9.5.16 - *2023-08-01*

- Clean up changelog formatting

## 9.5.15 - *2023-07-10*

## 9.5.14 - *2023-05-17*

## 9.5.13 - *2023-04-17*

## 9.5.12 - *2023-04-07*

- Standardise files with files in sous-chefs/repo-management

## 9.5.11 - *2023-04-01*

## 9.5.10 - *2023-03-02*

- Standardise files with files in sous-chefs/repo-management

## 9.5.9 - *2023-02-20*

- Standardise files with files in sous-chefs/repo-management

## 9.5.8 - *2023-02-16*

- Standardise files with files in sous-chefs/repo-management

## 9.5.7 - *2023-02-15*

## 9.5.6 - *2023-02-15*

- Standardise files with files in sous-chefs/repo-management

## 9.5.5 - *2023-02-14*

## 9.5.4 - *2022-12-08*

- Standardise files with files in sous-chefs/repo-management

## 9.5.3 - *2022-12-02*

- Standardise files with files in sous-chefs/repo-management

## 9.5.2 - *2022-03-28*

- Fix permissions on reusable workflow

## 9.5.1 - *2022-02-16*

- Remove delivery and move to calling RSpec directly via a reusable workflow
- Update tested platforms
- Cookstyle fixes

## 9.5.0 - *2021-09-13*

- Add new attribute 'repository_name' to set the name of the repository

## 9.4.0 - *2021-09-07*

- add user and password to jenkins_proxy

## 9.3.0 - *2021-08-31*

- Add `jnlp_options` for Windows agents

## 9.2.1 - *2021-08-30*

- Standardise files with files in sous-chefs/repo-management
- Various Cookstyle fixes

## 9.2.0 - *2021-08-29*

- Include yum-epel cookbook on RHEL platforms for new daemonize package dependency
- Add new `update_center_sleep` attribute to set the time to wait for updates to quiesce in Jenkins

## 9.1.0 - *2021-08-11*

- Added option for jenkins-cli authentication with a credential file - [@amcappelli](https://github.com/amcappelli) and [@ddegoede](https://github.com/ddegoede)

## 9.0.0 - *2021-07-19*

- Remove runit dependency
- Use systemd units instead of runit services

### Breaking Changes / Deprecations

- `jenkins_jnlp_slave`:
  - Renamed `runit_groups` property to `service_groups`
  - New service created -- old Runit service will need manual cleanup

- `jenkins::_master_war`:
  - New service created -- old Runit service will need manual cleanup

## 8.2.3 - *2021-03-25*

- Cookstyle fixes

## 8.2.2 - *2021-03-10*

- Allow setting of `JENKINS_ENABLE_ACCESS_LOG` for Rhel based controllers - [@mbaitelman](https://github.com/mbaitelman)

## 8.2.1 - *2021-02-10*

- Fix idempotency issue with `jenkins_user` when users have more than one public key

## 8.2.0 - *2021-02-08*

- Sous Chefs Adoption
- Fix deprecation warnings
- Cookstyle fixes
- Install missing font packages
- Remove Amazon Linux 1 and EL 6 testing
- Allow anonymous admin access during testing
- Add MAXOPENFILES to RHEL systems

## 8.1.0 - *2020-12-01*

- Fix the implementation of the cli user/password authentication method - [@ddegoede](https://github.com/ddegoede)

## 8.0.4 - *2020-11-24*

- Retry jenkins CLI command without authenticating after receiving an HTTP 401. - [@nuclearsandwich](https://github.com/nuclearsandwich)

## 8.0.3 - *2020-11-23*

- Remove touch command run as root from .war-based service definition - [@davidsainty](https://github.com/davidsainty)

## 8.0.2 (2020-09-14)

- jenkins_job: Dont quote param unnecessarily - [@mbaitelman](https://github.com/mbaitelman)

## 8.0.1 (2020-08-27)

- Remove .NET 2.0 from the Windows nodes as this is no longer supported by Jenkins- [@mbaitelman](https://github.com/mbaitelman)

## 8.0.0 (2020-07-14)

- Fixed groovy indentation errors in the generated code - [@ddegoede](https://github.com/ddegoede)
- Set default CLI protocol attribute to http now that remoting is deprecated in newer Jenkins releases - [@rjbaker](https://github.com/rjbaker)
- Adding support for SSH Slaves/SSH Build Agents plugin version >= 1.30 - [@joemillerr](https://github.com/joemillerr)
- Added attribute value for directory mode for jenkins directories
- Update resources so they can be found by chef 16 - [@codayblue](https://github.com/codayblue)
- Remove support for EOL Ubuntu < 16.04 in the java recipe - [@tas50](https://github.com/tas50)
- Update java recipe to install openjdk-1.8.0 on Debian - [@tas50](https://github.com/tas50)
- resolved cookstyle error: spec/recipes/java_spec.rb:6:7 warning: `ChefDeprecations/DeprecatedChefSpecPlatform`
- resolved cookstyle error: libraries/credentials_file.rb:91:33 convention: `Style/HashEachMethods`
- resolved cookstyle error: libraries/credentials_secret_text.rb:114:33 convention: `Style/HashEachMethods`
- resolved cookstyle error: libraries/credentials_user.rb:81:33 convention: `Style/HashEachMethods`
- resolved cookstyle error: libraries/slave.rb:401:33 convention: `Style/HashEachMethods`
- resolved cookstyle error: libraries/slave_jnlp.rb:64:14 warning: `ChefDeprecations/ChefWindowsPlatformHelper`
- resolved cookstyle error: libraries/slave_jnlp.rb:91:83 warning: `ChefDeprecations/ChefWindowsPlatformHelper`
- resolved cookstyle error: libraries/slave_jnlp.rb:95:17 warning: `ChefDeprecations/ChefWindowsPlatformHelper`

## 7.1.2 (2020-03-05)

- Add the actions back to the resources - [@tas50](https://github.com/tas50)
- Add redundant name attributes - [@tas50](https://github.com/tas50)
- Avoid chefspec deprecation warnings - [@tas50](https://github.com/tas50)

## 7.1.1 (2020-03-05)

- Simplify platform check logic - [@tas50](https://github.com/tas50)
- Remove unnecessary foodcritic comments - [@tas50](https://github.com/tas50)
- Cookstyle fixes - [@tas50](https://github.com/tas50)
- Switch to install_adoptopenjdk resource in java cookbook 7.0 for testing - [@tas50](https://github.com/tas50)

## 7.1.0 (2019-11-29)

- Ajp13 Port from attributes - [@rnt](https://github.com/rnt)
- Debug level for logs from attributes - [@rnt](https://github.com/rnt)
- Maximum number of HTTP worker threads from attributes - [@rnt](https://github.com/rnt)
- Maximum number of idle HTTP worker threads from attributes - [@rnt](https://github.com/rnt)
- Fix typo in java.rb recipe. - [@jugatsu](https://github.com/jugatsu)
- Auto accept Chef licenses when running tests - [@rjbaker](https://github.com/rjbaker)
- Switch to openjdk in testing since Oracle jdk artifacts have been removed - [@rjbaker](https://github.com/rjbaker)
- Cookstyle 5.10 fixes - [@tas50](https://github.com/tas50)
- Additional cookstyle fixes - [@tas50](https://github.com/tas50)

## 7.0.0 (2019-04-30)

- Require Chef 13 or later - [@Stromweld](https://github.com/Stromweld)
- Do not quote boolean parameters in the job resource - [@mbaitelman](https://github.com/mbaitelman)
- Resolve ProviderNotFound error in jenkins_view resource - [@eitoball](https://github.com/eitoball)
- Support installation on Debian 9 - [@mattray](https://github.com/mattray)
- Wire up JENKINS_ENABLE_ACCESS_LOG to attributes in the config - [@mattray](https://github.com/mattray)
- Fix the executor to -auth instead of --username, --password on the Jenkins CLI - Jakob Pfeiffer
- JNLP slave is configured to not use all the groups of the jenkins user - [@jonathanan](https://github.com/jonathanan)
- Update plugin resource to work with newer versions of Jenkins which handles dependencies and removes need for additional plugin method. This deprecated the install_deps property previously required  - [@Stromweld](https://github.com/Stromweld)

## 6.2.1 (2018-11-14)

- @josh-barker entirely rewrote our test suites. Suites have been consolidated, everything now passes, and all validation is performed with all new InSpec tests. Thanks Josh for this massive improvement.
- Fix bug when remote plugin is not found in plugin universe
- Fix broken delete action for jnlp slave
- Fix cloning resources attributes for/var/lib/jenkins
- Set httpKeepAliveTimeout to 5 minutes so that connections are not closed too early
- Increase slave launch timeout to 2 minutes for slow systems
- Add documentation about slave failure due to slow performance
- Mark windows template sensitive if setting password, remove default '.' for windows users domain

## 6.2.0 (2018-07-30)

- Code improvement for custom plugin update centre
- Don't fail on deprecations for now
- Remove respond_to? on chef_version in metadata
- Fix jenkins_view and jenkins_user resource errors

## 6.1.0 (2018-07-24)

- Added new jenkins_view resource
- Added new jenkins_proxy resource
- Allow jenkins_script to execute a groovy script on disk

## 6.0.0 (2018-02-16)

- Require Chef 12.14+ and remove compat_resource dependency

## 5.0.6 (2018-01-15)

- windows slave fixes

## 5.0.5 (2017-11-22)

- If the installed plugin version is a SNAPSHOT let it be instead of checking versions for updates
- Allow Jenkins to read system environment variables
- Fix permissions on /var/xxx/jenkins folders for Debian/CentOS
- Plugins: User & Group should be read from attributes
- Resolve Chef 13 failures by not passing new_resource into runit_service

## 5.0.4 (2017-08-28)

- Modified case statements to support package installation on Amazon Linux
- Changes endpoint for 'wait_until_ready' helper
- Fix permissions for plugin files downloaded from update center
- Wait for Jenkins in case of EADDRNOTAVAIL
- Change groovy scripts to use stdin instead of file. Fixes #620
- And change test to expect new format
- Ensure that we only reject the '-i key' part and not, for instance, parts that contain '-i' in larger strings.

## 5.0.3 (2017-07-04)

- Removed mention of Amazon Linux support from the readme. We will support this in the future, but at the moment the cookbook does not actually support Amazon Linux
- Note that Package installs of Jenkins now require Debian 9+ and Ubuntu 16.04+ due to Jenkins 2.66 now requiring Java 8 packages to be present
- Fix credentials_private_key to handle passphrase being nil
- Improve idempotence of user resource in case properties are not defined in the new resource
- Make sure plugin path has file:// appended
- Fix some typos in credentials_user that caused failures
- Remove foodcritic file we no longer need
- Remove the rakefile since we have delivery local mode now
- Remove maintainers logic and instead include a maintainers blurb in the readme
- Speed up specs and resolve deprecations

## 5.0.2 (2017-06-14)

- Fix regex for falling back to anonymous for failed authentication

## 5.0.1 (2017-05-01)

- Add -remoting option that is required due to [Jenkins issue](https://jenkins.io/blog/2017/04/26/security-advisory/). Attribute `['jenkins']['executor']['protocol']` has been added to allow for using the deprecated remoting option (default) or ssh/http in which attribute `['jenkins']['executor']['cli_user']` needs to be assigned.

## [5.0.0](https://github.com/chef-cookbooks/jenkins/tree/v5.0.0) (2017-03-08)

[Full Changelog](https://github.com/chef-cookbooks/jenkins/compare/v4.2.1...v5.0.0)
s

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

- Make slave_exe resource only get created if it is missing.

## v2.4.0 (2015-09-03)

- Ensure Jenkins home directory has correct ownership after package installation
- Fix for NPE when creating already registered slave with env vars defined
- Fix ArgumentError when comparing two versions not of the same type
- Don't mutate value when converting to Groovy; Fixes #371

- Automatically add "Logon As A Service" right to Windows slaves
- Allow optional 'keyserver' attribute for apt
- Add a `MAINTAINERS` file

## v2.3.1 (2015-05-19)

- Fix Travis badge
- Re-enable lazy attribute defaults in LWRP workaround for Chef 11
- Properly escape single quotes in Groovy code

- Download update center metadata every time

## v2.3.0 (2015-05-14)

### New Feature

- Add stable source support for package installation
- Add support for `jvm_options` on `slave_ssh` resource
- Support executing commands prior to launching Jenkins Windows slave
- Add username/password support to executor

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

- Instantiate Windows-specific resource class; Fixes #336
- Need to escape the `\n` when there are multiple public keys.

## v2.2.2 (2015-01-15)

- Gem::Version raising ArgumentError for weirdly versioned Jenkins plugins
- Force UTF-8 encoding when parsing update center JSON
- README grammar fixes

## v2.2.1 (2014-12-02)

- Ensure Win service install command respects alternate service names

## v2.2.0 (2014-12-02)

- Handle jobs that do not have a `disabled` attribute
- Remove unneeded service restart in Windows slaves
- Update Jenkins service check to use `WIN32OLE`
- Properly quote executor file paths cause $WINDOWS
- Properly escape backslashes in generated Groovy code
- Jenkins timeout shouldn't rescue Net::HTTP timeout
- Make sure Net::HTTP#use_ssl is turned on for https end-point
- Wrap converted Groovy strings in single quotes
- Recover from commands executed with unknown credentials. This should also fix some cases of JENKINS-22346.

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
- Added a *very* basic Java recipe with caveats
- Added a Jenkins master recipe (formerly called "server")
- Removed "node" recipes - they have all been replaced by HWRPs
- Removed proxy recipes
- Updated Debian and RedHat templates to the latest version
- Added the ability to add authentication
- Added custom ServerSpec matchers
- "node" renamed to "slave"
- "server" renamed to "master"

## v1.2.2

- **COOK-3742** - Remove trailing comma (restores compatability with Ruby 1.8)

## v1.2.0

- **COOK-3710** - Allow winsw url to be changed with a node attribute
- **COOK-3709** - Use correct attribute value for `java_home`
- **COOK-3701** - Fix a refactor bug where a template variable was removed that was used in a nested template
- **COOK-3594** - Fix MiniTest Chef Handler tests for directory permissions

## v1.1.0

- **COOK-3683** - Fix plugin provider failures finding the current plugin version
- **COOK-3667** - Unbreak Travis-CI integration
- **COOK-3623** - Fix issue where plugins were never updated even if you bump the plugin version in attributes
- **COOK-3620** - Fix Jenkins `_node_jnlp_test.rb` assumptions
- **COOK-3517** - Various bug fixes for `jenkins::windows`
- **COOK-3516** - Fix Jenkins slaves that use JNLP when Jenkins has security enabled
- **COOK-3619** - Support intermediate SSL certificates
- **COOK-3587** - Adding minitest-handler to the runlist for the node suite in Jenkins cookbook

## v1.0.0

- Initial Chef Software release

## v0.7.0

- Initial import from Heavywater upstream: <https://github.com/heavywater/chef-jenkins>
