jenkins Cookbook CHANGELOG
==========================
This file is used to list changes made in each version of the jenkins cookbook.

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
