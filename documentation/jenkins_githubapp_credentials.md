# jenkins_githubapp_credentials

Credentials for GitHub App. Requires Jenkins plugin `github-branch-source`.

Credentials use id, GitHub Application id, GitHub organization owner and private key.

[Setup guide](https://github.com/jenkinsci/github-branch-source-plugin/blob/ed20e60b071742c8d3397b533a4a4098755151e4/docs/github-app.adoc) for GitHub App with needed permissions.

Convert the private key to single line format with `sed -z 's/\n/\\n/g;s/,$/\n/' converted-github-app.pem`.

## Examples

```ruby
# Create private key credentials
jenkins_githubapp_credentials 'wcoyote' do
  app_id                '123456'
  description           'Wile E Coyote GitHub App'
  id                    'githubapp-wcoyote'
  owner                 'sous-chefs'
  private_key_pkcs8_pem '-----BEGIN PRIVATE KEY-----\nM...\n-----END PRIVATE KEY-----\n'
end
```

```ruby
# Delete private key
jenkins_githubapp_credentials 'wcoyote' do
  id     'githubapp-wcoyote'
  action :delete
end
```
