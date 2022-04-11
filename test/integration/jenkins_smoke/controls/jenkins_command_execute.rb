# copyright: 2018, The Authors

title 'Jenkins Command Execute'

control 'jenkins_command_execute-1.0' do
  impact 0.7
  title 'Users and plugins are installed after setting private key'

  describe service('jenkins') do
    it 'cannot have a reliably tested command' do
      pending('cannot have a reliably tested command')
      raise
    end
  end
end
