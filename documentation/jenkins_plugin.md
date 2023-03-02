# jenkins_plugin

This resource manages Jenkins plugins.

## Actions

- :install
- :uninstall
- :enable
- :disable

This uses the Jenkins CLI to install plugins. By default, it does a cold deploy, meaning the plugin is installed while Jenkins is still running. Some plugins may require you restart the Jenkins instance for their changed to take affect.

- **This resource does not install plugin dependencies from a a given hpi/jpi URL or a specific version - you must specify all plugin dependencies or Jenkins may not startup correctly!**

The `:install` action idempotently installs a Jenkins plugin on the current node. The name attribute corresponds to the name of the plugin on the Jenkins Update Center. You can also specify a particular version of the plugin to install. Finally, you can specify a full source URL or local path (on the node) to a plugin.

```ruby
# Install the latest version of the greenballs plugin and all dependencies
jenkins_plugin 'greenballs'

# Install version 1.3 of the greenballs plugin and no dependencies
jenkins_plugin 'greenballs' do
  version '1.3'
end

# Install a plugin from a given hpi (or jpi) and no dependencies
jenkins_plugin 'greenballs' do
  source 'http://updates.jenkins-ci.org/download/plugins/greenballs/1.10/greenballs.hpi'
end
```

Depending on the plugin, you may need to restart the Jenkins instance for the plugin to take affect:

```ruby
jenkins_plugin 'a_complicated_plugin' do
  notifies :restart, 'service[jenkins]', :immediately
end
```

For advanced users, this resource exposes an `options` attribute that will be passed to the installation command. For more information on the possible values of these options, please consult the documentation for your Jenkins installation.

```ruby
jenkins_plugin 'a_really_complicated_plugin' do
  options '-deploy -cold'
end
```

The `:uninstall` action removes (uninstalls) a Jenkins plugin idempotently on the current node.

```ruby
jenkins_plugin 'greenballs' do
  action :uninstall
end
```

The `:enable` action enables a plugin. If the plugin is not installed, an exception is raised. If the plugin is already enabled, no action is taken.

```ruby
jenkins_plugin 'greenballs' do
  action :enable
end
```

The `:disable` action disables a plugin. If the plugin is not installed, an exception is raised. If the plugin is already disabled, no action is taken.

```ruby
jenkins_plugin 'greenballs' do
  action :disable
end
```

**NOTE** You may need to restart Jenkins after changing a plugin. Because this varies on a case-by-case basis (and because everyone chooses to manage their Jenkins infrastructure differently) this resource does **NOT** restart Jenkins for you.
