# jenkins_password_credentials

Basic username + password credentials.

## Examples

```ruby
# Create password credentials
jenkins_password_credentials 'wcoyote' do
  id          'wcoyote-password'
  description 'Wile E Coyote'
  password    'beepbeep'
end
```

```ruby
# Delete password credentials
jenkins_password_credentials 'wcoyote' do
  id     'wcoyote-password'
  action :delete
end
```
