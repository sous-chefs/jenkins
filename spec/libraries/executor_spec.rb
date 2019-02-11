require 'spec_helper'

describe Jenkins::Executor do
  describe '.initialize' do
    it 'uses default options' do
      options = described_class.new.options
      expect(options[:cli]).to eq('/usr/share/jenkins/cli/java/cli.jar')
      expect(options[:java]).to eq('java')
    end

    it 'overrides with options from the initializer' do
      options = described_class.new(cli: 'foo', java: 'bar').options
      expect(options[:cli]).to eq('foo')
      expect(options[:java]).to eq('bar')
    end
  end

  describe '#execute!' do
    let(:shellout) { double(run_command: nil, error!: nil, stdout: '') }
    before { allow(Mixlib::ShellOut).to receive(:new).and_return(shellout) }

    it 'wraps the java and jar paths in quotes' do
      command = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" foo)
      expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
      subject.execute!('foo')
    end

    context 'when no options are given' do
      it 'builds the correct command' do
        command = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" foo)
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
        subject.execute!('foo')
      end
    end

    context 'when an :endpoint option is given' do
      it 'builds the correct command' do
        subject.options[:endpoint] = 'http://jenkins.ci'
        command = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" -s http://jenkins.ci foo)
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
        subject.execute!('foo')
      end

      it 'escapes the endpoint' do
        subject.options[:endpoint] = 'http://jenkins.ci?foo=this is a text'
        command = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" -s http://jenkins.ci?foo=this%20is%20a%20text foo)
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
        subject.execute!('foo')
      end
    end

    context 'when a :cli_username option is given' do
      context 'when a :cli_password option is given' do
        it 'adds -auth option' do
          subject.options[:username] = 'user'
          subject.options[:password] = 'password'
          command = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" -auth "user":"password" foo)
          expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
          subject.execute!('foo')
        end
      end
    end

    context 'when a :key option is given' do
      it 'builds the correct command' do
        subject.options[:key] = '/key/path.pem'
        command = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" -i "/key/path.pem" foo)
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
        subject.execute!('foo')
      end

      it 'wraps key path in quotes' do
        subject.options[:key] = '/key/path/to /pem with/spaces.pem'
        command = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" -i "/key/path/to /pem with/spaces.pem" foo)
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
        subject.execute!('foo')
      end

      context 'the private key is unknown to the Jenkins instance' do
        before do
          # This is really ugly but there is no easy way to stub a method to
          # raise an exception a set number of times.
          @times = 0
          allow(shellout).to receive(:error!) do
            @times += 1
            raise Mixlib::ShellOut::ShellCommandFailed unless @times > 2
          end
          allow(shellout).to receive(:exitstatus).and_return(255, 1, 0)
          allow(shellout).to receive(:stderr).and_return(
            'Authentication failed. No private key accepted.',
            'Exception in thread "main" java.io.EOFException',
            ''
          )
        end

        it 'retrys the command without a private key' do
          subject.options[:key] = '/key/path.pem'
          command = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" -i "/key/path.pem" foo)
          expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
          command_no_key = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" foo)
          expect(Mixlib::ShellOut).to receive(:new).with(command_no_key, timeout: 60)
          subject.execute!('foo')
        end
      end
    end

    context 'when a :proxy option is given' do
      it 'builds the correct command' do
        subject.options[:proxy] = 'http://proxy.jenkins.ci'
        command = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" -p http://proxy.jenkins.ci foo)
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
        subject.execute!('foo')
      end

      it 'escapes the proxy' do
        subject.options[:proxy] = 'http://proxy.jenkins.ci?foo=this is a text'
        command = %("java" -jar "/usr/share/jenkins/cli/java/cli.jar" -p http://proxy.jenkins.ci?foo=this%20is%20a%20text foo)
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
        subject.execute!('foo')
      end
    end

    context 'when :jvm_options option is given' do
      it 'builds the correct command' do
        subject.options[:jvm_options] = '-Djava.arg1=foo -Djava.arg2=bar'
        command = %("java" -Djava.arg1=foo -Djava.arg2=bar -jar "/usr/share/jenkins/cli/java/cli.jar" foo)
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60)
        subject.execute!('foo')
      end
    end

    context 'when execute! with options' do
      let(:stdin) { "hello\nworld" }
      it 'pass to shellout' do
        command = '"java" -jar "/usr/share/jenkins/cli/java/cli.jar" foo'
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 60, input: stdin)
        subject.execute!('foo', input: stdin)
      end
    end

    context 'when the command fails' do
      it 'raises an error' do
        allow(shellout).to receive(:error!).and_raise(RuntimeError)
        expect { subject.execute!('bad') }.to raise_error
      end
    end
  end

  describe '#execute' do
    before { allow(subject).to receive(:execute!) }

    it 'calls #execute!' do
      expect(subject).to receive(:execute).with('foo', 'bar')
      subject.execute('foo', 'bar')
    end

    context 'when the command fails' do
      it 'does not raise an error' do
        allow(subject).to receive(:execute!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        expect { subject.execute('foo') }.to_not raise_error
      end
    end
  end

  describe '#groovy!' do
    before { allow(subject).to receive(:execute!) }

    it 'calls execute!' do
      expect(subject).to receive(:execute!)
        .with('groovy =', input: 'script')
      subject.groovy('script')
    end
  end

  describe '#groovy' do
    before { allow(subject).to receive(:execute) }

    it 'calls execute' do
      expect(subject).to receive(:execute)
        .with('groovy =', input: 'script')
      subject.groovy('script')
    end
  end
end
