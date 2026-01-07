# jenkins_agent

**NOTE** The use of the Jenkins user resource requires the Jenkins SSH credentials plugin. This plugin is not shipped by default in jenkins 2.x.

This resource manages Jenkins agents, supporting the following actions:

```ruby
:create, :delete, :connect, :disconnect, :online, :offline
```

The following agent launch methods are supported:

- **JNLP/Java Web Start** - Starts an agent by launching an agent program through JNLP. The launch in this case is initiated by the agent, thus agents need not be IP reachable from the controller (e.g. behind the firewall). This launch method is supported on *nix and Windows platforms.
- **SSH** - Jenkins has a built-in SSH client implementation that it can use to talk to remote `sshd` daemon and start an agent. This is the most convenient and preferred method for Unix agents, which normally has `sshd` out-of-the-box.

The `jenkins_agent` resource is actually the base resource for several resources that map directly back to a launch method:

- `jenkins_jnlp_agent` - As JNLP agent connections are agent initiated, this resource should be part of an **agent**'s run list.
- `jenkins_ssh_agent` - As SSH agent connections are controller initiated, this resource should be part of a **controller**'s run list.

The `:create` action idempotently creates a Jenkins agent on the controller. The name attribute corresponds to the name of the agent (which is also used to uniquely identify the agent).

```ruby
# Create a basic JNLP agent
jenkins_jnlp_agent 'builder' do
  description 'A generic agent builder'
  remote_fs   '/home/jenkins'
  labels      ['builder', 'linux']
end

# Create a agent launched via SSH
jenkins_ssh_agent 'executor' do
  description 'Run test suites'
  remote_fs   '/share/executor'
  labels      ['executor', 'freebsd', 'jail']

  # SSH specific attributes
  host        '172.11.12.53' # or 'agent.example.org'
  user        'jenkins'
  credentials 'wcoyote'
  launch_timeout   30
  ssh_retries      5
  ssh_wait_retries 60
end

# A agent's executors, usage mode and availability can also be configured
jenkins_jnlp_agent 'smoke' do
  description     'Runs a series of high-level smoke tests'
  remote_fs       '/home/jenkins'
  executors       5
  usage_mode      'exclusive'
  availability    'demand'
  in_demand_delay 1
  idle_delay      3
  labels          ['runner', 'fast']

  # List of groups to run the agent service under
  service_groups  ['jenkins', 'docker']
end

# Create a agent with a full environment
jenkins_jnlp_agent 'integration' do
  description 'Runs the high-level integration suite'
  remote_fs   '/home/jenkins'
  labels      ['integration', 'rails', 'ruby']
  environment(
    RAILS_ENV: 'test',
    GCC:       '1_000_000_000'
  )
end

# Windows JNLP agent
jenkins_windows_agent 'mywinagent' do
  remote_fs 'C:/jenkins'
  user       '.\Administrator'
  password   'MyPassword'
end
```

The `:delete` action idempotently removes an agent from the cluster. Any services used to manage the underlying agent process will also be disabled.

```ruby
jenkins_jnlp_agent 'builder' do
  action :delete
end

jenkins_ssh_agent 'executor' do
  action :delete
end
```

The `:connect` action idempotently forces the controller to reconnect to the specified agent. You can use the base `jenkins_agent` resource or any of its children to perform the connection.

```ruby
jenkins_agent 'builder' do
  action :connect
end

jenkins_ssh_agent 'executor' do
  action :connect
end
```

The `:disconnect` action idempotently forces the controller to disconnect the specified agent. You can use the base `jenkins_agent` resource or any of its children to perform the connection.

```ruby
jenkins_agent 'builder' do
  action :disconnect
end

jenkins_ssh_agent 'executor' do
  action :disconnect
end
```

The `:online` action idempotently brings an agent back online. You can use the base `jenkins_agent` resource or any of its children to bring the agent online.

```ruby
jenkins_agent 'builder' do
  action :online
end

jenkins_ssh_agent 'executor' do
  action :online
end
```

The `:offline` action idempotently takes an agent temporarily offline. An optional reason for going offline can be provided with the `offline_reason` attribute. You can use the base `jenkins_agent` resource or any of its children to take an agent offline.

```ruby
jenkins_agent 'builder' do
  action :offline
end

jenkins_ssh_agent 'executor' do
  offline_reason 'ran out of energon'
  action :offline
end
```

**NOTE** It's worth noting the somewhat confusing differences between _disconnecting_ and _off-lining_ a agent:

- **Disconnect** - Instantly closes the channel of communication between the controller and agent. Currently executing jobs will be terminated immediately. If an agent is configured with an availability of `always` the controller will attempt to reconnect to the agent.
- **Offline** - Keeps the channel of communication between the controller and agent open. Currently executing jobs will be allowed to finish, but no new jobs will be scheduled on the agent.

## Backwards Compatibility

The following resources and actions are backwards compatible with the legacy slave/master naming and resource names:

- `jenkins_slave` is an alias for `jenkins_agent`
- `jenkins_jnlp_slave` is an alias for `jenkins_jnlp_agent`
- `jenkins_ssh_slave` is an alias for `jenkins_ssh_agent`
- `jenkins_windows_slave` is an alias for `jenkins_windows_agent`
