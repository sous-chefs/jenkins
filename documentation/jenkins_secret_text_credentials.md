# jenkins_secret_text_credentials

Generic secret text. Requires the the `credentials-binding` plugin.

## Examples

```ruby
# Create secret text credentials
jenkins_secret_text_credentials 'wcoyote' do
  id          'wcoyote-secret'
  description 'Wile E Coyote Secret'
  secret      'Some secret text'
end
```

```ruby
# Delete secret text credentials
jenkins_secret_text_credentials 'wcoyote' do
  id     'wcoyote-secret'
  action :delete
end
```

### jenkins_file_credentials

Generic file credentials.

```ruby
# Create file credentials
jenkins_file_credentials 'wcoyote' do
  id          'wcoyote-file'
  description 'Wile E Coyote File'
  filename    'file.txt'
  data        'my file content'
end
```

```ruby
# Delete file credentials
jenkins_file_credentials 'wcoyote' do
  id     'wcoyote-file'
  action :delete
end
```

## Scopes

Credentials in Jenkins can be created with 2 different "scopes" which determines where the credentials can be used:

- **GLOBAL** - This credential is available to the object on which the credential is associated and all objects that are children of that object. Typically you would use global-scoped credentials for things that are needed by jobs.
- **SYSTEM** - This credential is only available to the object on which the credential is associated. Typically you would use system-scoped credentials for things like email auth, slave connection, etc, i.e. where the Jenkins instance itself is using the credential. Unlike the global scope, this significantly restricts where the credential can be used, thereby providing a higher degree of confidentiality to the credential.

The credentials created with the `jenkins_credentials` resources are assigned a `GLOBAL` scope.
