# require_relative 'credentials'
# require_relative 'credentials_user'

property :username,
          String,
          name_property: true
property :password,
          String,
          required: true

unified_mode true
use 'partials/_credentials'

def load_current_resource
  @current_resource ||= Resource::JenkinsPasswordCredentials.new(new_resource.name)

  super

  @current_resource.password(current_credentials[:password]) if current_credentials
  @current_credentials
end

action_class do
  #
  # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
  #
  def attribute_to_property_map
    { password: 'credentials.password.plainText' }
  end
end
