#
# Cookbook:: jenkins
# Library:: ssh_agent_helpers
#

require_relative 'agent_helpers'

module Jenkins
  module SshAgentHelpers
    include Jenkins::AgentHelpers

    def attribute_to_property_map
      {
        host: 'launcher.host',
        port: 'launcher.port',
        credentials: 'launcher.credentialsId',
      }
    end
  end
end
