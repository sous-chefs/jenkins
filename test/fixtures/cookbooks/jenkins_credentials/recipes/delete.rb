fixture_data_base_path = ::File.join(::File.dirname(Chef::Config[:config_file]), 'data')

# test deletion with base resource
jenkins_password_credentials 'user1_delete' do
  id 'user1_delete'
  description 'passwords are for suckers'
  password 'superseekret'

  action [:create, :delete]
end

# test deletion with `jenkins_password_credentials` child resource
jenkins_password_credentials 'user2_delete' do
  id '73e11302-d446-4ba0-8aa4-f5821f74d36f'
  password 'superseekret'

  action [:create, :delete]
end

# Test delete by specifying a string-based ID
jenkins_password_credentials 'user3_delete' do
  id 'user3_delete'
  password 'superseekret'

  action [:create, :delete]
end

# test deletion with base resource
jenkins_private_key_credentials 'private_key_credentials_delete1' do
  id 'private_key_credentials_delete1'
  private_key lazy { OpenSSL::PKey::RSA.new(File.read("#{fixture_data_base_path}/test_id_rsa_with_passphrase"), 'secret').to_pem }
  passphrase 'secret'

  action [:create, :delete]
end

# test deletion with `jenkins_private_key_credentials` child resource
jenkins_private_key_credentials 'private_key_credentials_delete2' do
  id 'private_key_credentials_delete2'
  description 'this is more like it'
  private_key lazy { File.read("#{fixture_data_base_path}/test_id_rsa") }

  action [:create, :delete]
end

# Test basic private key credentials creation
jenkins_private_key_credentials 'private_key_credentials_delete3' do
  description 'I specified an ID'
  id '866952b8-e1ea-4ee1-b769-e159681cb894'
  private_key lazy { File.read("#{fixture_data_base_path}/test_id_rsa") }

  action [:create, :delete]
end

jenkins_secret_text_credentials 'secret_text_credentials_to_delete' do
  id 'secret_text_credentials_to_delete'
  secret '$uper$ecret'

  action [:create, :delete]
end

jenkins_file_credentials 'file_to_delete' do
  id 'file_to_delete'
  filename 'file_to_delete'
  data 'some data'

  action [:create, :delete]
end
