# jenkins_job

This resource manages Jenkins jobs

## Actions

- :create
- :delete
- :disable
- :enable
- :build

The resource is fully idempotent and convergent. It also supports why-run mode.

The `:create` action requires a Jenkins job `config.xml`. This config file must exist on the target node and contain a valid Jenkins job configuration file. Because the Jenkins CLI actually reads and generates its own copy of this file, **do NOT** write this configuration inside of the Jenkins job. We recommend putting them in Chef's file cache path:

```ruby
xml = File.join(Chef::Config[:file_cache_path], 'bacon-config.xml')

# You could also use a `cookbook_file` or pure `file` resource to generate
# content at this path.
template xml do
  source 'custom-config.xml.erb'
end

# Create a jenkins job (default action is `:create`)
jenkins_job 'bacon' do
  config xml
end
```

```ruby
jenkins_job 'bacon' do
  action :delete
end
```

You can disable a Jenkins job by specifying the `:disable` option. This will disable an existing job, if and only if that job exists and is enabled. If the job does not exist, an exception is raised.

```ruby
jenkins_job 'bacon' do
  action :disable
end
```

You can enable a Jenkins job by specifying the `:enable` option. This will enable an existing job, if and only if that job exists and is disabled. If the job does not exist, an exception is raised.

```ruby
jenkins_job 'bacon' do
  action :enable
end
```

You can execute a Jenkins job by specifying the `:build` option. This will run the job, if and only if that job exists and is enabled. If the job does not exist, an exception is raised.

```ruby
jenkins_job 'my-parameterized-job' do
  parameters(
    'STRING_PARAM' => 'meeseeks',
    'BOOLEAN_PARAM' => true,
  )
  # if true will live stream the console output of the executing job  (default is true)
  stream_job_output true
  # if true will block the Chef client run until the build is completed or aborted (defaults to true)
  wait_for_completion true
  action :build
end
```
