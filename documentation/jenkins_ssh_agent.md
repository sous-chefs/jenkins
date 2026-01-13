# jenkins_ssh_agent

Manages Jenkins SSH agents. SSH agents are initiated from the Jenkins controller via SSH connection, making them ideal for Unix/Linux nodes with SSH access.

## Actions

- :create (default)
- :delete
- :connect
- :disconnect
- :online
- :offline

## Properties

### Basic Properties

- `agent_name` - (name property) The name of the agent
- `description` - Description for the agent (default: "Jenkins agent {agent_name}")
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

### SSH-Specific Properties

- `host` - Hostname or IP address of the agent
- `port` - SSH port (default: 22)
- `credentials` - Jenkins credentials ID for SSH authentication
- `user` - SSH user to connect as (default: 'jenkins')
- `jvm_options` - JVM options for the agent
- `java_path` - Path to Java executable on the agent
- `command_prefix` - Command to prepend to the launch command
- `command_suffix` - Command to append to the launch command
- `launch_timeout` - Timeout in seconds for launching the agent
- `ssh_retries` - Number of SSH connection retries
- `ssh_wait_retries` - Number of retries while waiting for SSH

## Examples

```ruby
# Create a basic SSH agent
jenkins_ssh_agent 'builder' do
  description 'Build agent'
  remote_fs   '/home/jenkins'
  host        'builder.example.com'
  credentials 'jenkins-ssh-key'
  labels      ['builder', 'linux']
end
```

```ruby
# Create an SSH agent with custom port and user
jenkins_ssh_agent 'executor' do
  description 'Test executor'
  remote_fs   '/opt/jenkins'
  host        '192.168.1.100'
  port        2222
  user        'ci-user'
  credentials 'ci-ssh-credentials'
  labels      ['executor', 'test']
end
```

```ruby
# Create an SSH agent with retry configuration
jenkins_ssh_agent 'flaky-agent' do
  description      'Agent with unreliable network'
  remote_fs        '/home/jenkins'
  host             'flaky.example.com'
  credentials      'ssh-key'
  launch_timeout   60
  ssh_retries      10
  ssh_wait_retries 30
  labels           ['flaky', 'retry']
end
```

```ruby
# Create an SSH agent with environment variables
jenkins_ssh_agent 'integration' do
  description 'Integration test agent'
  remote_fs   '/home/jenkins'
  host        'integration.example.com'
  credentials 'jenkins-ssh'
  environment(
    TEST_ENV: 'integration',
    DB_HOST:  'db.example.com'
  )
  labels ['integration', 'database']
end
```

```ruby
# Create an SSH agent with command prefix/suffix
jenkins_ssh_agent 'docker-agent' do
  description    'Agent with Docker environment'
  remote_fs      '/home/jenkins'
  host           'docker.example.com'
  credentials    'docker-ssh'
  command_prefix 'docker exec jenkins-agent'
  labels         ['docker', 'container']
end
```

```ruby
# Delete an SSH agent
jenkins_ssh_agent 'builder' do
  action :delete
end
```

```ruby
# Connect/disconnect an agent
jenkins_ssh_agent 'builder' do
  action :connect
end

jenkins_ssh_agent 'builder' do
  action :disconnect
end
```

```ruby
# Take an agent offline/online
jenkins_ssh_agent 'builder' do
  offline_reason 'Maintenance window'
  action :offline
end

jenkins_ssh_agent 'builder' do
  action :online
end
```

**NOTE** SSH agents are initiated from the Jenkins controller, so this resource should be part of the **controller node's** run list. The controller must have SSH access to the agent node.

**NOTE** The `credentials` property must reference valid SSH credentials stored in Jenkins (created via `jenkins_private_key_credentials` or similar resources).
