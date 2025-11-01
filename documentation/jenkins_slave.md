# jenkins_slave

**NOTE** The use of the Jenkins user resource requires the Jenkins SSH credentials plugin. This plugin is not shipped by default in jenkins 2.x.

This resource manages Jenkins slaves, supporting the following actions:

```ruby
:create, :delete, :connect, :disconnect, :online, :offline
```

The following agent launch methods are supported:

- **JNLP/Java Web Start** - Starts a agent by launching an agent program through JNLP. The launch in this case is initiated by the agent, thus slaves need not be IP reachable from the master (e.g. behind the firewall). This launch method is supported on *nix and Windows platforms.
- **SSH** - Jenkins has a built-in SSH client implementation that it can use to talk to remote `sshd` daemon and start a agent agent. This is the most convenient and preferred method for Unix slaves, which normally has `sshd` out-of-the-box.

The `jenkins_slave` resource is actually the base resource for several resources that map directly back to a launch method:

- `jenkins_jnlp_slave` - As JNLP Agente connections are agent initiated, this resource should be part of a **agent**'s run list.
- `jenkins_ssh_slave` - As SSH Agente connections are master initiated, this resource should be part of a **master**'s run list.

The `:create` action idempotently creates a Jenkins agent on the master. The name attribute corresponds to the name of the agent (which is also used to uniquely identify the agent).

```ruby
# Create a basic JNLP agent
jenkins_jnlp_slave 'builder' do
  description 'A generic agent builder'
  remote_fs   '/home/jenkins'
  labels      ['builder', 'linux']
end

# Create a agent launched via SSH
jenkins_ssh_slave 'executor' do
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
jenkins_jnlp_slave 'smoke' do
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
jenkins_jnlp_slave 'integration' do
  description 'Runs the high-level integration suite'
  remote_fs   '/home/jenkins'
  labels      ['integration', 'rails', 'ruby']
  environment(
    RAILS_ENV: 'test',
    GCC:       '1_000_000_000'
  )
end

# Windows JNLP agent
jenkins_windows_slave 'mywinslave' do
  remote_fs 'C:/jenkins'
  user       '.\Administrator'
  password   'MyPassword'
end
```

The `:delete` action idempotently removes a agent from the cluster. Any services used to manage the underlying agent process will also be disabled.

```ruby
jenkins_jnlp_slave 'builder' do
  action :delete
end

jenkins_ssh_slave 'executor' do
  action :delete
end
```

The `:connect` action idempotently forces the master to reconnect to the specified agent. You can use the base `jenkins_slave` resource or any of its children to perform the connection.

```ruby
jenkins_slave 'builder' do
  action :connect
end

jenkins_ssh_slave 'executor' do
  action :connect
end
```

The `:disconnect` action idempotently forces the master to disconnect the specified agent. You can use the base `jenkins_slave` resource or any of its children to perform the connection.

```ruby
jenkins_slave 'builder' do
  action :disconnect
end

jenkins_ssh_slave 'executor' do
  action :disconnect
end
```

The `:online` action idempotently brings a agent back online. You can use the base `jenkins_slave` resource or any of its children to bring the agent online.

```ruby
jenkins_slave 'builder' do
  action :online
end

jenkins_ssh_slave 'executor' do
  action :online
end
```

The `:offline` action idempotently takes a agent temporarily offline. An optional reason for going offline can be provided with the `offline_reason` attribute. You can use the base `jenkins_slave` resource or any of its children to take a agent offline.

```ruby
jenkins_slave 'builder' do
  action :offline
end

jenkins_ssh_slave 'executor' do
  offline_reason 'ran out of energon'
  action :offline
end
```

**NOTE** It's worth noting the somewhat confusing differences between _disconnecting_ and _off-lining_ a agent:

- **Disconnect** - Instantly closes the channel of communication between the master and agent. Currently executing jobs will be terminated immediately. If a agent is configured with an availability of `always` the master will attempt to reconnect to the agent.
- **Offline** - Keeps the channel of communication between the master and agent open. Currently executing jobs will be allowed to finish, but no new jobs will be scheduled on the agent.
