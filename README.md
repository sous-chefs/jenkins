# jenkins Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/jenkins.svg)](https://supermarket.chef.io/cookbooks/jenkins)
[![CI State](https://github.com/sous-chefs/jenkins/workflows/ci/badge.svg)](https://github.com/sous-chefs/jenkins/actions?query=workflow%3Aci)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

Installs and configures Jenkins CI controller & agents. Resource providers to support automation via jenkins-cli, including job create/update.

Breaking migration notes live in [migration.md](./migration.md).

## Maintainers

This cookbook is maintained by the Sous Chefs. The Sous Chefs are a community of Chef cookbook maintainers working together to maintain important cookbooks. If you’d like to know more please visit [sous-chefs.org](https://sous-chefs.org/) or come chat with us on the Chef Community Slack in [#sous-chefs](https://chefcommunity.slack.com/messages/C2V7B88SF).

## Requirements

### Platforms

- AlmaLinux 8+
- Amazon Linux 2023
- CentOS Stream 9+
- Debian 12+
- Fedora latest
- Oracle Linux 8+
- Rocky Linux 8+
- Ubuntu 22.04+

### Chef

- Chef Infra Client 15.3+

#### Java cookbook

This cookbook does not install, manage, or manipulate a JDK, as that is outside of the scope of Jenkins. The `package` installation method will automatically pull in a valid Java if one does not exist on Debian. RHEL jenkins packages do not depend on java as there are far too many options for a package to do the right thing. We recommend including the java cookbook on your system which allows for either openJDK or Oracle JDK installations.

## Migration

The legacy attribute interface has been removed. Configure controller install defaults on `jenkins_install`, and configure runtime overrides for CLI-driven resources with `jenkins_executor_config` or `node.run_state[:jenkins_runtime_config]`.

See [migration.md](./migration.md) for the breaking mappings.

## Examples

Documentation and examples are provided inline using YARD. The tests and fixture cookbooks in `test` and `test/fixtures` are intended to be a further source of examples.

## Install

Use `jenkins_install` to install a controller. Package and WAR installs are both supported.

```ruby
jenkins_install 'controller' do
  install_method 'package'
  endpoint 'https://jenkins.example.com'
  home '/var/lib/jenkins'
  java '/usr/bin/java'
  update_center_mirror 'https://updates.jenkins.io'
  update_center_channel 'stable'
  update_center_sleep 10
end
```

## Resources

### Core Resources

- [jenkins_command](./documentation/jenkins_command.md)
- [jenkins_job](./documentation/jenkins_job.md)
- [jenkins_plugin](./documentation/jenkins_plugin.md)
- [jenkins_proxy](./documentation/jenkins_proxy.md)
- [jenkins_script](./documentation/jenkins_script.md)
- [jenkins_user](./documentation/jenkins_user.md)
- [jenkins_view](./documentation/jenkins_view.md)

### Credential Resources

- [jenkins_credentials](./documentation/jenkins_credentials.md)
- [jenkins_file_credentials](./documentation/jenkins_file_credentials.md)
- [jenkins_githubapp_credentials](./documentation/jenkins_githubapp_credentials.md)
- [jenkins_password_credentials](./documentation/jenkins_password_credentials.md)
- [jenkins_private_key_credentials](./documentation/jenkins_private_key_credentials.md)
- [jenkins_secret_text_credentials](./documentation/jenkins_secret_text_credentials.md)

### Agent Resources

- [jenkins_agent](./documentation/jenkins_agent.md)
- [jenkins_jnlp_agent](./documentation/jenkins_jnlp_slave.md)
- [jenkins_ssh_agent](./documentation/jenkins_ssh_agent.md)
- [jenkins_windows_agent](./documentation/jenkins_windows_slave.md)

Legacy slave-named aliases remain for compatibility.

## Caveats

### Authentication

If you use or plan to use authentication for your Jenkins cluster (which we highly recommend), you will need to configure CLI authentication. Jenkins 2.332.1+ requires authentication for CLI commands by default.

#### Username/Password Authentication

```ruby
jenkins_executor_config 'controller auth' do
  endpoint 'https://jenkins.example.com'
  cli_username 'admin'
  cli_password 'admin_api_token_or_password'
  timeout 300
end
```

#### Credential File Authentication

For credential-file auth, point the runtime config at a `username:password` or `username:api_token` file:

```ruby
jenkins_executor_config 'controller auth' do
  endpoint 'https://jenkins.example.com'
  cli_credential_file '/path/to/credentials_file'
  timeout 300
end
```

You can also continue to set the value directly in `run_state`:

```ruby
node.run_state[:jenkins_cli_credential_file] = '/path/to/credentials_file'
```

The credentials file should contain `username:password` or `username:api_token`.

**Note:** Using an API token instead of a password is recommended for security. You can generate an API token from the Jenkins user configuration page.

#### SSH Key Authentication (Legacy)

For older Jenkins installations or when SSH-based authentication is preferred, you can set a private key in the `run_state`:

```ruby
node.run_state[:jenkins_private_key]
```

The underlying executor class (which all custom resources use) intelligently adds authentication information to the Jenkins CLI commands if this value is set. The method used to generate and populate this key-pair is left to the user:

```ruby
# Using search
master = search(:node, 'fqdn:master.ci.example.com').first
node.run_state[:jenkins_private_key] = master['jenkins']['private_key']

# Using encrypted data bags and chef-sugar
private_key = encrypted_data_bag_item('jenkins', 'keys')['private_key']
node.run_state[:jenkins_private_key] = private_key
```

The associated public key must be set on a Jenkins user. You can use the `jenkins_user` resource to create this pairing. Here's an example that loads a keypair and assigns it appropriately:

```ruby
jenkins_keys = encrypted_data_bag_item('jenkins', 'keys')

require 'openssl'
require 'net/ssh'

key = OpenSSL::PKey::RSA.new(jenkins_keys['private_key'])
private_key = key.to_pem
public_key = "#{key.ssh_type} #{[key.to_blob].pack('m0')}"

# Create the Jenkins user with the public key
jenkins_user 'chef' do
  public_keys [public_key]
end

# Set the private key on the Jenkins executor
node.run_state[:jenkins_private_key] = private_key
```

Please note that older versions of Jenkins (< 1.555) permitted login via CLI for a user defined in Jenkins configuration with an SSH public key but not present in the actual SecurityRealm, and this is no longer permitted. If an operation requires any special permission at all, you must authenticate as a real user. This means that if you have LDAP or GitHub OAuth based authn/authz enabled the user you are using for configuration tasks must have an associated account in the external services. Please see [JENKINS-22346](https://issues.jenkins-ci.org/browse/JENKINS-22346) for more details.

### Jenkins 2

Jenkins 2 enables an install wizard by default. To make sure you can manipulate the jenkins instance, keep the setup-wizard JVM flag when overriding JVM options:

```ruby
jenkins_install 'controller' do
  jvm_options '-Djenkins.install.runSetupWizard=false'
end
```

This is done by default, but must be kept when overriding the jvm_options!

### Proxies

If you need to pass through a proxy to communicate between your controllers and agents, configure it on the executor runtime:

```ruby
jenkins_executor_config 'controller proxy' do
  proxy '1.2.3.4:5678'
end
```

## Development

Please see the [Contributing](CONTRIBUTING.md) and [Testing](TESTING.md) Guidelines.

## Contributors

This project exists thanks to all the people who [contribute.](https://opencollective.com/sous-chefs/contributors.svg?width=890&button=false)

### Backers

Thank you to all our backers!

![https://opencollective.com/sous-chefs#backers](https://opencollective.com/sous-chefs/backers.svg?width=600&avatarHeight=40)

### Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website.

![https://opencollective.com/sous-chefs/sponsor/0/website](https://opencollective.com/sous-chefs/sponsor/0/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/1/website](https://opencollective.com/sous-chefs/sponsor/1/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/2/website](https://opencollective.com/sous-chefs/sponsor/2/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/3/website](https://opencollective.com/sous-chefs/sponsor/3/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/4/website](https://opencollective.com/sous-chefs/sponsor/4/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/5/website](https://opencollective.com/sous-chefs/sponsor/5/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/6/website](https://opencollective.com/sous-chefs/sponsor/6/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/7/website](https://opencollective.com/sous-chefs/sponsor/7/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/8/website](https://opencollective.com/sous-chefs/sponsor/8/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/9/website](https://opencollective.com/sous-chefs/sponsor/9/avatar.svg?avatarHeight=100)
