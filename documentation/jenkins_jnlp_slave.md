# jenkins_jnlp_slave

Manages Jenkins JNLP (Java Network Launch Protocol) agents. JNLP agents are initiated from the agent node itself, making them ideal for nodes behind firewalls or with restricted network access.

## Actions

- :create (default)
- :delete
- :connect
- :disconnect
- :online
- :offline

## Properties

### Basic Properties

- `slave_name` - (name property) The name of the agent
- `description` - Description for the agent (default: "Jenkins agent {slave_name}")
- `remote_fs` - Remote filesystem root for the agent (default: '/home/jenkins')
- `executors` - Number of executors (default: 1)
- `usage_mode` - How Jenkins schedules builds on this node: 'exclusive' or 'normal' (default: 'normal')
- `labels` - Array of labels for the agent (default: [])
- `environment` - Hash of environment variables
- `offline_reason` - Reason for taking the agent offline

### Availability Properties

- `availability` - When to bring the agent online: 'always' or 'demand'
- `in_demand_delay` - Number of minutes to wait before starting the agent when demand occurs (default: 0)
- `idle_delay` - Number of minutes to wait before stopping the agent when idle (default: 1)

### JNLP-Specific Properties

- `user` - System user to run the agent service (default: 'jenkins')
- `group` - System group for the agent service (default: 'jenkins')
- `service_name` - Name of the systemd service (default: 'jenkins-slave')
- `service_groups` - Array of groups the service should run under (default: [group])
- `jvm_options` - JVM options for the agent
- `java_path` - Path to Java executable

## Examples

```ruby
# Create a basic JNLP agent
jenkins_jnlp_slave 'builder' do
  description 'A generic agent builder'
  remote_fs   '/home/jenkins'
  labels      ['builder', 'linux']
end
```

```ruby
# Create a JNLP agent with multiple executors
jenkins_jnlp_slave 'executor' do
  description 'Multi-threaded executor'
  remote_fs   '/home/jenkins'
  executors   5
  labels      ['executor', 'parallel']
end
```

```ruby
# Create an agent with exclusive usage and demand availability
jenkins_jnlp_slave 'smoke' do
  description     'Runs a series of high-level smoke tests'
  remote_fs       '/home/jenkins'
  executors       5
  usage_mode      'exclusive'
  availability    'demand'
  in_demand_delay 1
  idle_delay      3
  labels          ['runner', 'fast']
end
```

```ruby
# Create an agent with custom service groups (e.g., for Docker access)
jenkins_jnlp_slave 'docker-builder' do
  description    'Agent with Docker access'
  remote_fs      '/home/jenkins'
  service_groups ['jenkins', 'docker']
  labels         ['docker', 'builder']
end
```

```ruby
# Create an agent with environment variables
jenkins_jnlp_slave 'integration' do
  description 'Runs the high-level integration suite'
  remote_fs   '/home/jenkins'
  labels      ['integration', 'rails', 'ruby']
  environment(
    RAILS_ENV: 'test',
    RUBY_VERSION: '3.0.0'
  )
end
```

```ruby
# Delete a JNLP agent
jenkins_jnlp_slave 'builder' do
  action :delete
end
```

```ruby
# Connect/disconnect an agent
jenkins_jnlp_slave 'builder' do
  action :connect
end

jenkins_jnlp_slave 'builder' do
  action :disconnect
end
```

```ruby
# Take an agent offline/online
jenkins_jnlp_slave 'builder' do
  offline_reason 'Maintenance window'
  action :offline
end

jenkins_jnlp_slave 'builder' do
  action :online
end
```

**NOTE** JNLP agents are initiated from the agent node, so this resource should be part of the **agent node's** run list. The agent needs network access to the Jenkins controller's JNLP port (typically 50000).

**NOTE** The `:create` action creates a systemd service on Linux to manage the JNLP agent process.
