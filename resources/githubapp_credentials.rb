require 'json'

unified_mode true

provides :jenkins_githubapp_credentials

property :id, String, required: true
property :app_id, String, name_property: true
property :private_key_pkcs8_pem, String, required: true, sensitive: true
property :owner, String, required: true
property :description, String,
         default: lazy { |r| "Credentials for GitHub App #{r.app_id} - created by Chef" }

# Mark resource as sensitive by default
def initialize(name, run_context = nil)
  super
  @sensitive = true
end

load_current_value do
  current_creds = current_credentials_from_jenkins

  if current_creds
    id current_creds[:id]
    description current_creds[:description]
    app_id current_creds[:app_id]
    private_key_pkcs8_pem current_creds[:private_key_pkcs8_pem] if current_creds[:private_key_pkcs8_pem]
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
        import hudson.util.Secret
        import org.jenkinsci.plugins.github_branch_source.*

        global_domain = Domain.global()
        credentials_store =
          Jenkins.instance.getExtensionList(
            'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
          )[0].getStore()

        private_key = """#{new_resource.private_key_pkcs8_pem}
        """

        githubAppPrivateKey = Secret.fromString(private_key)
        credentials = new GitHubAppCredentials(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.description)},
          #{convert_to_groovy(new_resource.app_id)},
          githubAppPrivateKey

        )

        String orgOwner = #{convert_to_groovy(new_resource.owner)}
        credentials.setOwner(orgOwner)

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
  include Jenkins::Helper
  include Jenkins::CredentialsHelpers

  def current_credentials_from_jenkins
    return @current_credentials if @current_credentials

    Chef::Log.debug "Load #{new_resource} credentials information"

    json = executor.groovy! <<-EOH.gsub(/^ {6}/, '')
      import org.jenkinsci.plugins.github_branch_source.*;

      #{credentials_for_id_groovy(new_resource.id, 'credentials')}

      if(credentials == null) {
        return null
      }

      current_credentials = [
        id:credentials.id,
        description:credentials.description,
        app_id:credentials.username
      ]

      current_credentials['private_key_pkcs8_pem'] = credentials.privateKey.plainText

      builder = new groovy.json.JsonBuilder(current_credentials)
      println(builder)
    EOH

    return if json.nil? || json.empty?

    @current_credentials = JSON.parse(json, symbolize_names: true)
    @current_credentials = convert_blank_values_to_nil(@current_credentials)
  end

  def correct_config?
    wanted_credentials = {
      description: new_resource.description,
      app_id: new_resource.app_id,
      private_key_pkcs8_pem: new_resource.private_key_pkcs8_pem,
    }

    # Don't compare the ID as it is generated
    current_credentials_from_jenkins.dup.tap { |c| c.delete(:id) } == convert_blank_values_to_nil(wanted_credentials)
  end

  def credentials_for_id_groovy(id, groovy_variable_name)
    <<-EOH.gsub(/^ {6}/, '')
      #{groovy_variable_name} = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
        com.cloudbees.plugins.credentials.Credentials.class,
        Jenkins.instance,
        null,
        null
      ).find { it.id == #{convert_to_groovy(id)} }
    EOH
  end
end
