unified_mode true

include Jenkins::Helper
use 'partials/_credentials'

property :description,
         String,
         default: lazy { |new_resource| "Credentials for #{new_resource.username} - created by Chef" }

def load_current_resource
  @current_resource ||= Resource::JenkinsUserCredentials.new(new_resource.name)

  super

  @current_resource.username(current_credentials[:username]) if current_credentials
  @current_resource
end

action_class do
  def fetch_existing_credentials_groovy(groovy_variable_name)
    <<-EOH.gsub(/^ {8}/, '')
      #{credentials_for_id_groovy(new_resource.id, groovy_variable_name)}
    EOH
  end

  #
  # @see Chef::Resource::JenkinsCredentials#resource_attributes_groovy
  #
  def resource_attributes_groovy(groovy_variable_name)
    <<-EOH.gsub(/^ {8}/, '')
      #{groovy_variable_name} = [
        id:credentials.id,
        description:credentials.description,
        username:credentials.username
      ]
    EOH
  end

  #
  # @see Chef::Resource::JenkinsCredentials#correct_config?
  #
  def correct_config?
    wanted_credentials = {
      description: new_resource.description,
      username: new_resource.username,
    }

    attribute_to_property_map.each_key do |key|
      wanted_credentials[key] = new_resource.send(key)
    end

    # Don't compare the ID as it is generated
    current_credentials.dup.tap { |c| c.delete(:id) } == convert_blank_values_to_nil(wanted_credentials)
  end
end
