# frozen_string_literal: true

# WARNING: This resource is for TESTING ONLY
# It grants anonymous users ADMINISTER permission which is a SECURITY RISK
# NEVER use this in production

unified_mode true

resource_name :jenkins_test_auth
provides :jenkins_test_auth

action :enable do
  # Create init script to grant anonymous admin permission
  # This MUST be created BEFORE Jenkins starts for the first time
  file '/var/lib/jenkins/init.groovy.d/test-anonymous-admin.groovy' do
    content <<~GROOVY
      import jenkins.model.*
      import hudson.security.*

      def instance = Jenkins.getInstance()

      // WARNING: TESTING ONLY - grants anonymous full admin access
      def strategy = new GlobalMatrixAuthorizationStrategy()
      strategy.add(Jenkins.ADMINISTER, "anonymous")
      instance.setAuthorizationStrategy(strategy)
      instance.save()

      println("TEST MODE: Granted anonymous ADMINISTER permission")
    GROOVY
    owner 'jenkins'
    group 'jenkins'
    mode '0644'
  end
end
