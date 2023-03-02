# jenkins_user

**NOTE** The use of the Jenkins user resource requires the Jenkins mailer plugin. This plugin is not shipped by default in jenkins 2.x.

This resource manages Jenkins users, supporting the following actions:

```ruby
:create, :delete
```

This uses the Jenkins groovy API to create users.

The `:create` action idempotently creates a Jenkins user on the current node. The id attribute corresponds to the username of the id of the user on the target node. You may also specify a name, email, and list of SSH keys.

```ruby
# Create a Jenkins user
jenkins_user 'grumpy'

# Create a Jenkins user with specific attributes
jenkins_user 'grumpy' do
  full_name    'Grumpy Dwarf'
  email        'grumpy@example.com'
  public_keys  ['ssh-rsa AAAAB3NzaC1y...']
end
```

The `:delete` action removes a Jenkins user from the system.

```ruby
jenkins_user 'grumpy' do
  action :delete
end
```
