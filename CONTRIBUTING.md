Contributing to the Jenkins Cookbook
====================================
The Jenkins cookbook uses GitHub to triage, manage, and track issues and pull requests to the cookbook. GitHub has excellent documentation on how to [fork a repository and start contributing](https://help.github.com/articles/fork-a-repo.).

All contributors are welcome to submit patches, but we ask you keep the following guidelines in mind:

- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Prerequisites](#prerequisites)

Please also keep in mind:

- Be patient as not all items will be tested or reviewed immediately by the core team.
- Be receptive and responsive to feedback about your additions or changes. The core team and/or other community members may make suggestions or ask questions about your change. This is part of the review process, and helps everyone to understand what is happening, why it is happening, and potentially optimizes your code.
- Be understanding

If you're looking to contribute but aren't sure where to start, check out the open issues.


Will Not Merge
--------------
This second details Pull Requests that we will **not** merge.

1. New features without accompanying Test Kitchen tests
1. New features without accompanying usage documentation
1. Pull requests with a broken build (Travis will automatically mark the build as passing/failing on GitHub, but you can also check the build manually by visiting https://travis-ci.org/opscode-cookbooks/jenkins)


Coding Standards
----------------
The submitted code should be compatible with the standard Ruby coding guidelines. Here are some additional resources:

- [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide)
- [GitHub Styleguide](https://github.com/styleguide/ruby)

This cookbook is equipped with Rubocop, which will fail the build for violating these standards.


Testing
-------
Whether your pull request is a bug fix or introduces new classes or methods to the project, we kindly ask that you include tests for your changes. Even if it's just a small improvement, a test is necessary to ensure the bug is never re-introduced.

We understand that not all users are familiar with the testing ecosystem. This cookbook is fully-tested using [Foodcritic](https://github.com/acrmp/foodcritic), [Rubocop](https://github.com/bbatsov/rubocop), and [Test Kitchen](https://github.com/test-kitchen/test-kitchen) with [Serverspec](https://github.com/serverspec/serverspec) bussers.


Prerequisites
-------------
Developing this cookbook requires a sane Ruby 1.9+ environment with `bundler` installed. In order to run the Test Kitchen integration suite, you must also have Vagrant and VirtualBox installed:

- [Vagrant](https://vagrantup.com)
- [VirtualBox](https://virtualbox.org)

### CLA
For non-trival updates (such as new features or bugfixes), we do require a Contributor License Agreement from Chef Software. If you have already signed a CLA under Opscode or Chef Software, you are already covered. For more information, see [Chef Software's Contribution Guidelines](https://wiki.opscode.com/display/chef/How+to+Contribute), but please note that we do **not** use the JIRA ticketing system.


Process
-------
1. Clone the git repository from GitHub:

        $ git clone git@github.com:opscode-cookbooks/jenkins.git

2. Install the dependencies using bundler:

        $ bundle install

3. Create a branch for your changes:

        $ git checkout -b my_bug_fix

4. Make any changes
5. Write tests to support those changes.
6. Run the tests:

        $ bundle exec rake

7. Assuming the tests pass, open a Pull Request on GitHub


Do's and Don't's
----------------
- **Do** include tests for your contribution
- **Do** request feedback via the Chef mailing list, Twitter, or IRC
- **Do NOT** open JIRA tickets
- **Do NOT** break existing behavior (unless intentional)
- **Do NOT** modify the version number in the `metadata.rb`
- **Do NOT** modify the CHANGELOG
