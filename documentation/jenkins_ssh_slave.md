# jenkins_ssh_slave

Manages Jenkins SSH slaves. SSH slaves are initiated from the Jenkins master via SSH connection, making them ideal for Unix/Linux nodes with SSH access.

## Actions

- :create (default)
- :delete
- :connect
- :disconnect
- :online
- :offline

## Properties

### Basic Properties

- `slave_name` - (name property) The name of the slave
- `description` - Description for the slave (default: "Jenkins slave {slave_name}")
- `remote_fs` - Remote filesystem root for the slave (default: '/home/jenkins')
- `executors` - Number of executors (default: 1)
- `usage_mode` - How Jenkins schedules builds on this node: 'exclusive' or 'normal' (default: 'normal')
- `labels` - Array of labels for the slave (default: [])
- `environment` - Hash of environment variables
- `offline_reason` - Reason for taking the slave offline

### Availability Properties

- `availability` - When to bring the slave online: 'always' or 'demand'
- `in_demand_delay` - Number of minutes to wait before starting the slave when demand occurs (default: 0)
- `idle_delay` - Number of minutes to wait before stopping the slave when idle (default: 1)

### SSH-Specific Properties

- `host` - Hostname or IP address of the slave
- `port` - SSH port (default: 22)
- `credentials` - Jenkins credentials ID for SSH authentication
- `user` - SSH user to connect as (default: 'jenkins')
- `jvm_options` - JVM options for the slave
- `java_path` - Path to Java executable on the slave
- `command_prefix` - Command to prepend to the launch command
- `command_suffix` - Command to append to the launch command
- `launch_timeout` - Timeout in seconds for launching the slave
- `ssh_retries` - Number of SSH connection retries
- `ssh_wait_retries` - Number of retries while waiting for SSH

## Examples

```ruby
# Create a basic SSH slave
jenkins_ssh_slave 'builder' do
  description 'Build slave'
  remote_fs   '/home/jenkins'
  host        'builder.example.com'
  credentials 'jenkins-ssh-key'
  labels      ['builder', 'linux']
end
```

```ruby
# Create an SSH slave with custom port and user
jenkins_ssh_slave 'executor' do
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
# Create an SSH slave with retry configuration
jenkins_ssh_slave 'flaky-slave' do
  description      'Slave with unreliable network'
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
# Create an SSH slave with environment variables
jenkins_ssh_slave 'integration' do
  description 'Integration test slave'
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
# Create an SSH slave with command prefix/suffix
jenkins_ssh_slave 'docker-slave' do
  description    'Slave with Docker environment'
  remote_fs      '/home/jenkins'
  host           'docker.example.com'
  credentials    'docker-ssh'
  command_prefix 'docker exec jenkins-agent'
  labels         ['docker', 'container']
end
```

```ruby
# Delete an SSH slave
jenkins_ssh_slave 'builder' do
  action :delete
end
```

```ruby
# Connect/disconnect a slave
jenkins_ssh_slave 'builder' do
  action :connect
end

jenkins_ssh_slave 'builder' do
  action :disconnect
end
```

```ruby
# Take a slave offline/online
jenkins_ssh_slave 'builder' do
  offline_reason 'Maintenance window'
  action :offline
end

jenkins_ssh_slave 'builder' do
  action :online
end
```

**NOTE** SSH slaves are initiated from the Jenkins master, so this resource should be part of the **master node's** run list. The master must have SSH access to the slave node.

**NOTE** The `credentials` property must reference valid SSH credentials stored in Jenkins (created via `jenkins_private_key_credentials` or similar resources).
