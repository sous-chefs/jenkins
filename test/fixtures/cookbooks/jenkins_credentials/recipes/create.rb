require 'openssl'

include_recipe 'jenkins::server'

# Test basic password credentials creation
jenkins_password_credentials 'schisamo' do
  description 'passwords are for suckers'
  password 'superseekret'
end

# Test specifying an ID
jenkins_password_credentials 'schisamo2' do
  id '38537014-ec66-49b5-aff2-aed1c19e2989'
  password 'superseekret'
end

# Test basic private key credentials creation
jenkins_private_key_credentials 'jenkins' do
  description 'this is more like it'
  private_key File.read(File.expand_path('../../../../../data/data/test_id_rsa', __FILE__))
end

# Test private key credentials with passphrase
jenkins_private_key_credentials 'jenkins2' do
  private_key OpenSSL::PKey::RSA.new(File.read(File.expand_path('../../../../../data/data/test_id_rsa_with_passphrase', __FILE__)), 'secret').to_pem
  passphrase 'secret'
end
