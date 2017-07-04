#
# Cookbook:: jenkins
# HWRP:: credentials_secret_file
#
# Author:: Dimitry Polyanitsa <d.polyanitsa@criteo.com>
#
# Copyright:: 2016-2017, Criteo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative 'credentials'

class Chef
  class Resource::JenkinsSecretFileCredentials < Resource::JenkinsUserCredentials
    attribute :description,
              kind_of: String,
              default: lazy { |new_resource| "Credentials for #{new_resource.filename} - created by Chef" }
    attribute :filename,
              kind_of: String,
              name_attribute: true
    attribute :data,
              kind_of: String,
              required: true
  end
end

class Chef
  class Provider::JenkinsSecretFileCredentials < Provider::JenkinsUserCredentials
    use_inline_resources
    provides :jenkins_secret_file_credentials

    def load_current_resource
      @current_resource ||= Resource::JenkinsSecretFileCredentials.new(new_resource.name)

      super

      if current_credentials
        @current_resource.filename(current_credentials[:filename])
        @current_resource.data(current_resource[:data])
      end

      @current_resource
    end

    private

    #
    # @see Chef::Resource::JenkinsCredentials#credentials_groovy
    #
    def credentials_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        import com.cloudbees.plugins.credentials.CredentialsScope
        import java.nio.charset.StandardCharsets
        import org.apache.commons.codec.binary.Base64
        import org.apache.commons.fileupload.FileItem
        import org.apache.commons.fileupload.FileItemHeaders
        import org.apache.commons.lang.NotImplementedException
        import org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl

        class VirtualFileItem implements FileItem {
          String getName() { #{convert_to_groovy(new_resource.filename)} }
          byte[] get() { Base64.decodeBase64('#{new_resource.data}') }

          void delete() { throw new NotImplementedException() }
          String getContentType() { throw new NotImplementedException() }
          String getFieldName() { throw new NotImplementedException() }
          InputStream getInputStream() { throw new NotImplementedException() }
          OutputStream getOutputStream() { throw new NotImplementedException() }
          long getSize() { throw new NotImplementedException() }
          String getString() { throw new NotImplementedException() }
          String getString(String encoding) { throw new NotImplementedException() }
          boolean isFormField() { throw new NotImplementedException() }
          boolean isInMemory() { throw new NotImplementedException() }
          void setFieldName(String name) { throw new NotImplementedException() }
          void setFormField(boolean state) { throw new NotImplementedException() }
          void write(File file) { throw new NotImplementedException() }
          FileItemHeaders getHeaders() { throw new NotImplementedException() }
          void setHeaders(FileItemHeaders headers) { throw new NotImplementedException() }
        }

        credentials = new FileCredentialsImpl(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.description)},
          new VirtualFileItem(),
          null,
          null
        )
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#fetch_existing_credentials_groovy
    #
    def fetch_existing_credentials_groovy(groovy_variable_name)
      <<-EOH.gsub(/ ^{8}/, '')
        import jenkins.model.Jenkins;
        import hudson.util.Secret;
        import com.cloudbees.plugins.credentials.common.IdCredentials
        import com.cloudbees.plugins.credentials.CredentialsProvider

        available_credentials =
          CredentialsProvider.lookupCredentials(
            IdCredentials.class,
            Jenkins.getInstance(),
            hudson.security.ACL.SYSTEM
          ).findAll({
            it.id == #{convert_to_groovy('credentials.id')}
          })

        #{groovy_variable_name} = available_credentials.size() > 0 ? available_credentials[0] : null
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#resource_attributes_groovy
    #
    def resource_attributes_groovy(groovy_variable_name)
      <<-EOH.gsub(/ ^{8}/, '')
        #{groovy_variable_name} = [
          id:credentials.id,
          filename:credentials.filename
        ]
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
    #
    def attribute_to_property_map
      {
        filename: 'credentials.fileName',
        data: 'credentials.data',
      }
    end

    #
    # @see Chef::Resource::JenkinsCredentials#correct_config?
    #
    def correct_config?
      wanted_credentials = {
        description: new_resource.description,
        filename: new_resource.filename,
        data: new_resource.data,
      }

      attribute_to_property_map.keys.each do |key|
        wanted_credentials[key] = new_resource.send(key)
      end
    end
  end
end
