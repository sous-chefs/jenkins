# jenkins_proxy

This resource manages Jenkins HTTP proxy information

## Actions

- :config
- :remove

This uses the Jenkins groovy API to configure the HTTP proxy information, that is provided on the _Advanced_ tab of the _Plugin Manager_.

The `:config` action idempotently configure the Jenkins HTTP proxy information on the current node. The proxy attribute corresponds to the proxy server name and port number that have to use on the target node. You may also specify a list of no proxy host names with the noproxy attribute. The default is _localhost_ and _127.0.0.1_. If you need to authenticate you can set username and password attributes.

```ruby
# Basic proxy configuration
jenkins_proxy '1.2.3.4:5678'

# Basic proxy configuration with user/password
jenkins_proxy '1.2.3.4:5678' do
  username 'sous'
  password 'chefs'
end

# Expanded proxy configuration
jenkins_proxy '5.6.7.8:9012' do
  noproxy ['localhost', '127.0.0.1', 'nohost', '*.nodomain']
end

# Expanded proxy configuration with user/password
jenkins_proxy '5.6.7.8:9012' do
  username 'sous'
  password 'chefs'
  noproxy ['localhost', '127.0.0.1', 'nohost', '*.nodomain']
end
```

The `:remove` action removes the Jenkins HTTP proxy information from the system.

```ruby
jenkins_proxy '1.2.3.4:5678' do
  action :remove
end
```
