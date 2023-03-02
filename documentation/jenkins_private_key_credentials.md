# jenkins_private_key_credentials

Credentials that use a username + private key (optionally protected with a passphrase).

## Examples

```ruby
# Create private key credentials
jenkins_private_key_credentials 'wcoyote' do
  id          'wcoyote-key'
  description 'Wile E Coyote'
  private_key "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQ..."
end

# Private keys with a passphrase will also work
jenkins_private_key_credentials 'wcoyote' do
  id          'wcoyote-key'
  description 'Eile E Coyote'
  private_key "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQ..."
  passphrase  'beepbeep'
end
```

```ruby
# Delete private key
jenkins_private_key_credentials 'wcoyote' do
  id     'wcoyote-key'
  action :delete
end
```
