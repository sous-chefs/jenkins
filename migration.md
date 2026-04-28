# Jenkins Custom Resource Migration

This cookbook now finishes the custom-resource migration as a breaking change.

## What changed

* The legacy `attributes/` directory is removed.
* Runtime defaults now come from resource properties and `node.run_state[:jenkins_runtime_config]`.
* `jenkins_install` seeds controller runtime values such as `endpoint`, `home`, `java`, controller ownership, and update-center settings for later resources in the same run.
* `jenkins_executor_config` is the supported runtime override surface for controller endpoint, home, timeout, proxy, Java path, CLI auth, protocol, and update-center settings.
* Shared agent properties now live in `resources/_partial/_agent.rb`.
* The cookbook no longer creates or depends on an anonymous-admin bootstrap script. Secure Jenkins setup must use real authentication.

## Attribute mapping

* `node['jenkins']['java']` -> `jenkins_install java` or `jenkins_executor_config java`
* `node['jenkins']['master']['home']` / `node['jenkins']['controller']['home']` -> `jenkins_install home` or `jenkins_executor_config home`
* `node['jenkins']['master']['endpoint']` / `node['jenkins']['controller']['endpoint']` -> `jenkins_install endpoint` or `jenkins_executor_config endpoint`
* `node['jenkins']['master']['mirror']`, `channel`, `update_center_sleep` -> `jenkins_install update_center_*` or `jenkins_executor_config update_center_*`
* `node['jenkins']['executor']['timeout']`, `proxy`, `jvm_options`, `protocol`, `cli_user`, `cli_username`, `cli_password`, `cli_credential_file` -> `jenkins_executor_config`
* `node['jenkins']['master']['use_system_accounts']` -> `jenkins_jnlp_agent use_system_accounts`

## Security migration

Use real controller credentials instead of disabling security:

```ruby
jenkins_executor_config 'controller auth' do
  endpoint 'https://jenkins.example.com'
  cli_username 'chef'
  cli_password 'api-token-or-password'
  timeout 300
end
```

Or use a credentials file:

```ruby
jenkins_executor_config 'controller auth' do
  endpoint 'https://jenkins.example.com'
  cli_credential_file '/var/lib/jenkins/.cli-credentials'
  timeout 300
end
```

The credentials file must contain `username:password` or `username:api_token`.
