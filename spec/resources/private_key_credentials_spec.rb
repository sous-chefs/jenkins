require 'spec_helper'

describe 'jenkins_private_key_credentials custom resource' do
  PRIVATE_KEY = <<~KEY.freeze
    -----BEGIN PRIVATE KEY-----
    MIIBVAIBADANBgkqhkiG9w0BAQEFAASCAT4wggE6AgEAAkEA/Fu0qiWDCRmc1ood
    oPH8u9NL16SZUkST0cHVqLjZ6eTAcfvhDicDWOn7+tmnnu5Qu69/hcuHoIUwuoIh
    o5gMTwIDAQABAkBOnULqvkTT0ObK7rvMJ5ZT7L7zrpMUzcg+z+N/bBZ2he4QkWVU
    /JBwwR76BKqJIfsNcv2yoBjKoz1C1dvHasoBAiEA/2pyskU8qui2zh5B6W1WmG4n
    LQl8Y+i9fa5CpbywG50CIQD873ene3Ma4SIhFR+1/uCyFy/oFTbrzxpCOCVrfBcR
    2wIgbu6cwjCwGMraGsupdOi4I5w0B6uHCx2ar2twJuu80UECIQDB7bkIKJawXT0V
    sGSH3cvZv/1zLBDX7ApuCy5lotbtUQIgGEFtNp5jD+ahliwiJPk3WxBKHueMtXGt
    oLHZQLvnj74=
    -----END PRIVATE KEY-----
  KEY

  platform 'ubuntu'
  step_into :jenkins_private_key_credentials

  let(:executor) { instance_double(Jenkins::Executor) }

  before do
    allow_any_instance_of(Jenkins::Helper).to receive(:executor)
      .and_return(executor)
    allow(executor).to receive(:groovy!).and_return(nil, '')
  end

  context 'when creating private key credentials' do
    recipe do
      jenkins_private_key_credentials 'jenkins' do
        id '78d4bc59-4345-4cd7-aff6-c86bc539eac4'
        description 'Test user'
        private_key PRIVATE_KEY
      end
    end

    it 'loads current credentials before converging' do
      expect { chef_run }.not_to raise_error
      expect(executor).to have_received(:groovy!).at_least(:once)
    end
  end
end
