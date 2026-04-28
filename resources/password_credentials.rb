require 'json'

unified_mode true

resource_name :jenkins_password_credentials
provides :jenkins_password_credentials

include Jenkins::PasswordCredentialsHelpers

property :id, String, required: true
property :username, String, name_property: true
property :password, String, required: true, sensitive: true
property :description, String,
         default: lazy { |r| "Credentials for #{r.username} - created by Chef" }

# Mark resource as sensitive by default
def initialize(name, run_context = nil)
  super
  @sensitive = true
end

load_current_value do |new_resource|
  current_creds = current_credentials_from_jenkins(new_resource)

  if current_creds
    id current_creds[:id]
    description current_creds[:description]
    username current_creds[:username]
    password current_creds[:password] if current_creds[:password]
  else
    current_value_does_not_exist!
  end
end

action :create do
  if current_resource && correct_config?
    Chef::Log.info("#{new_resource} exists - skipping")
  else
    converge_by("Create #{new_resource}") do
      executor.groovy! <<-EOH.gsub(/^ {8}/, '')
        import jenkins.model.*
        import com.cloudbees.plugins.credentials.*
        import com.cloudbees.plugins.credentials.domains.*
        import com.cloudbees.plugins.credentials.impl.*

        global_domain = Domain.global()
        credentials_store =
          Jenkins.instance.getExtensionList(
            'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
          )[0].getStore()

        credentials = new UsernamePasswordCredentialsImpl(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.description)},
          #{convert_to_groovy(new_resource.username)},
          #{convert_to_groovy(new_resource.password)}
        )

        #{credentials_for_id_groovy(new_resource.id, 'existing_credentials')}

        if(existing_credentials != null) {
          credentials_store.updateCredentials(
            global_domain,
            existing_credentials,
            credentials
          )
        } else {
          credentials_store.addCredentials(global_domain, credentials)
        }
      EOH
    end
  end
end

action :delete do
  if current_resource
    converge_by("Delete #{new_resource}") do
      executor.groovy! <<-EOH.gsub(/^ {8}/, '')
        import jenkins.model.*
        import com.cloudbees.plugins.credentials.*;

        global_domain = com.cloudbees.plugins.credentials.domains.Domain.global()
        credentials_store =
          Jenkins.instance.getExtensionList(
            'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
          )[0].getStore()

        #{credentials_for_id_groovy(new_resource.id, 'existing_credentials')}

        if(existing_credentials != null) {
          credentials_store.removeCredentials(
            global_domain,
            existing_credentials
          )
        }
      EOH
    end
  else
    Chef::Log.debug("#{new_resource} does not exist - skipping")
  end
end

action_class do
  include Jenkins::PasswordCredentialsHelpers

  def correct_config?
    wanted_credentials = {
      description: new_resource.description,
      username: new_resource.username,
      password: new_resource.password,
    }

    # Don't compare the ID as it is generated
    current_credentials_from_jenkins.dup.tap { |c| c.delete(:id) } == convert_blank_values_to_nil(wanted_credentials)
  end
end
