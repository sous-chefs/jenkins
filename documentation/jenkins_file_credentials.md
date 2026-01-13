# jenkins_file_credentials

File-based credentials for storing sensitive file content.

## Actions

- :create (default)
- :delete

## Properties

- `id` - (required) The unique identifier for the credentials
- `filename` - (name property) The filename for the credential file
- `data` - (required, sensitive) The file content/data to store
- `description` - Description for the credentials (default: "Credentials for {filename} - created by Chef")

## Examples

```ruby
# Create file credentials
jenkins_file_credentials 'my-secret-file' do
  id          'secret-file-id'
  filename    'secret.key'
  data        File.read('/path/to/local/secret.key')
  description 'Secret key file'
end
```

```ruby
# Create file credentials with inline content
jenkins_file_credentials 'config-file' do
  id   'app-config'
  data <<-EOH
    api_key=secretvalue
    endpoint=https://api.example.com
  EOH
end
```

```ruby
# Delete file credentials
jenkins_file_credentials 'my-secret-file' do
  id     'secret-file-id'
  action :delete
end
```

**NOTE** This resource marks itself as sensitive by default to prevent credential data from being logged.
