# jenkins_windows_agent

Manages Jenkins JNLP agents on Windows nodes. This is a specialized version of the JNLP agent resource designed for Windows environments.

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
- `remote_fs` - Remote filesystem root for the agent (default: 'C:\\Jenkins')
- `executors` - Number of executors (default: 1)
- `usage_mode` - How Jenkins schedules builds on this node: 'exclusive' or 'normal' (default: 'normal')
- `labels` - Array of labels for the agent (default: [])
- `environment` - Hash of environment variables
- `offline_reason` - Reason for taking the agent offline

### Availability Properties

- `availability` - When to bring the agent online: 'always' or 'demand'
- `in_demand_delay` - Number of minutes to wait before starting the agent when demand occurs (default: 0)
- `idle_delay` - Number of minutes to wait before stopping the agent when idle (default: 1)

### Windows-Specific Properties

- `user` - Windows user to run the agent service (default: 'Administrator')
- `password` - (sensitive) Password for the Windows user
- `jvm_options` - JVM options for the agent
- `java_path` - Path to Java executable on Windows

## Examples

```ruby
# Create a basic Windows agent
jenkins_windows_agent 'win-builder' do
  remote_fs 'C:/Jenkins'
  user      '.\\Administrator'
  password  'SecurePassword123'
  labels    ['windows', 'builder']
end
```

```ruby
# Create a Windows agent with custom user
jenkins_windows_agent 'win-executor' do
  description 'Windows test executor'
  remote_fs   'D:/Jenkins'
  user        'DOMAIN\\jenkins-user'
  password    'P@ssw0rd'
  executors   4
  labels      ['windows', 'executor', 'tests']
end
```

```ruby
# Create a Windows agent with environment variables
jenkins_windows_agent 'dotnet-builder' do
  description 'Windows .NET builder'
  remote_fs   'C:/Jenkins'
  user        '.\\Jenkins'
  password    'MyPassword'
  environment(
    'DOTNET_CLI_HOME' => 'C:\\dotnet',
    'MSBUILD_PATH'    => 'C:\\Program Files\\MSBuild\\15.0\\Bin'
  )
  labels ['windows', 'dotnet', 'msbuild']
end
```

```ruby
# Create a Windows agent with exclusive usage
jenkins_windows_agent 'win-integration' do
  description 'Windows integration testing'
  remote_fs   'C:/Jenkins'
  user        '.\\TestUser'
  password    'TestPass123'
  usage_mode  'exclusive'
  executors   2
  labels      ['windows', 'integration']
end
```

```ruby
# Delete a Windows agent
jenkins_windows_agent 'win-builder' do
  action :delete
end
```

```ruby
# Take a Windows agent offline
jenkins_windows_agent 'win-builder' do
  offline_reason 'Windows updates'
  action :offline
end
```

```ruby
# Bring a Windows agent back online
jenkins_windows_agent 'win-builder' do
  action :online
end
```

**NOTE** Windows agents use JNLP for connection, similar to `jenkins_jnlp_agent`, but with Windows-specific service management.

**NOTE** The `password` property is marked as sensitive to prevent credential exposure in logs.

**NOTE** Ensure Java is installed on the Windows agent and accessible in the system PATH, or specify the path via the `java_path` property.

**NOTE** The user account must have appropriate permissions to run services and access the `remote_fs` directory.
