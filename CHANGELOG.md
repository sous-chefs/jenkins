jenkins Cookbook CHANGELOG
==========================
This file is used to list changes made in each version of the jenkins cookbook.

v2.0.0 (2014-01-14)
-------------------
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


v1.2.2
------
### Bug
- **[COOK-3742](https://tickets.opscode.com/browse/COOK-3742)** - Remove trailing comma (restores compatability with Ruby 1.8)


v1.2.0
------
### Improvement
- **[COOK-3710](https://tickets.opscode.com/browse/COOK-3710)** - Allow winsw url to be changed with a node attribute

### Bug
- **[COOK-3709](https://tickets.opscode.com/browse/COOK-3709)** - Use correct attribute value for `java_home`
- **[COOK-3701](https://tickets.opscode.com/browse/COOK-3701)** - Fix a refactor bug where a template variable was removed that was used in a nested template
- **[COOK-3594](https://tickets.opscode.com/browse/COOK-3594)** - Fix MiniTest Chef Handler tests for directory permissions


v1.1.0
------
### Bug
- **[COOK-3683](https://tickets.opscode.com/browse/COOK-3683)** - Fix plugin provider failures finding the current plugin version
- **[COOK-3667](https://tickets.opscode.com/browse/COOK-3667)** - Unbreak Travis-CI integration
- **[COOK-3623](https://tickets.opscode.com/browse/COOK-3623)** - Fix issue where plugins were never updated even if you bump the plugin version in attributes
- **[COOK-3620](https://tickets.opscode.com/browse/COOK-3620)** - Fix Jenkins `_node_jnlp_test.rb` assumptions
- **[COOK-3517](https://tickets.opscode.com/browse/COOK-3517)** - Various bug fixes for `jenkins::windows`
- **[COOK-3516](https://tickets.opscode.com/browse/COOK-3516)** - Fix Jenkins slaves that use JNLP when Jenkins has security enabled

### New Feature
- **[COOK-3619](https://tickets.opscode.com/browse/COOK-3619)** - Support intermediate SSL certificates

### Improvement
- **[COOK-3587](https://tickets.opscode.com/browse/COOK-3587)** - Adding minitest-handler to the runlist for the node suite in Jenkins cookbook

v1.0.0
------

- Initial Opscode release

v0.7.0
------

- Initial import from Heavywater upstream: https://github.com/heavywater/chef-jenkins
