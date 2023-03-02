# jenkins_command

This resource executes arbitrary commands against the [Jenkins CLI](https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+CLI)

## Actions

- :execute

## Examples

To perform a restart

```ruby
jenkins_command 'safe-restart'
```

To reload the configuration from disk:

```ruby
jenkins_command 'reload-configuration'
```

To prevent Jenkins from starting any new builds (in preparation for a shutdown):

```ruby
jenkins_command 'quiet-down'
```

**NOTE** You must add your own `not_if`/`only_if` guards to the `jenkins_command` to prevent duplicate commands from executing. Just like Chef's core `execute` resource, the `jenkins_command` resource has no way of being idempotent.
