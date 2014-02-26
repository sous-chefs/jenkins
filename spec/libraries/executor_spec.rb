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
    before { Mixlib::ShellOut.stub(:new).and_return(shellout) }

    context 'when no options are given' do
      it 'builds the correct command' do
        command = 'java -jar /usr/share/jenkins/cli/java/cli.jar foo'
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 30)
        subject.execute!('foo')
      end
    end

    context 'when an :endpoint option is given' do
      it 'builds the correct command' do
        subject.options[:endpoint] = 'http://jenkins.ci'
        command = 'java -jar /usr/share/jenkins/cli/java/cli.jar -s http://jenkins.ci foo'
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 30)
        subject.execute!('foo')
      end

      it 'escapes the endpoint' do
        subject.options[:endpoint] = 'http://jenkins.ci?foo=this is a text'
        command = 'java -jar /usr/share/jenkins/cli/java/cli.jar -s http://jenkins.ci?foo=this%20is%20a%20text foo'
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 30)
        subject.execute!('foo')
      end
    end

    context 'when a :key option is given' do
      it 'builds the correct command' do
        subject.options[:key] = '/key/path.pem'
        command = 'java -jar /usr/share/jenkins/cli/java/cli.jar -i /key/path.pem foo'
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 30)
        subject.execute!('foo')
      end

      it 'shell escapes the key path' do
        subject.options[:key] = '/key/path/to /pem with/spaces.pem'
        command = 'java -jar /usr/share/jenkins/cli/java/cli.jar -i /key/path/to\\ /pem\\ with/spaces.pem foo'
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 30)
        subject.execute!('foo')
      end
    end

    context 'when a :proxy option is given' do
      it 'builds the correct command' do
        subject.options[:proxy] = 'http://proxy.jenkins.ci'
        command = 'java -jar /usr/share/jenkins/cli/java/cli.jar -p http://proxy.jenkins.ci foo'
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 30)
        subject.execute!('foo')
      end

      it 'escapes the proxy' do
        subject.options[:proxy] = 'http://proxy.jenkins.ci?foo=this is a text'
        command = 'java -jar /usr/share/jenkins/cli/java/cli.jar -p http://proxy.jenkins.ci?foo=this%20is%20a%20text foo'
        expect(Mixlib::ShellOut).to receive(:new).with(command, timeout: 30)
        subject.execute!('foo')
      end
    end

    context 'when the command fails' do
      it 'raises an error' do
        shellout.stub(:error!).and_raise(RuntimeError)
        expect { subject.execute!('bad') }.to raise_error
      end
    end
  end

  describe '#execute' do
    before { subject.stub(:execute!) }

    it 'calls #execute!' do
      expect(subject).to receive(:execute).with('foo', 'bar')
      subject.execute('foo', 'bar')
    end

    context 'when the command fails' do
      it 'does not raise an error' do
        subject.stub(:execute!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        expect { subject.execute('foo') }.to_not raise_error
      end
    end
  end

  describe '#groovy!' do
    before { subject.stub(:execute!) }

    it 'calls execute!' do
      expect(subject).to receive(:execute!)
        .with("groovy = <<-GROOVY_SCRIPT\nscript\nGROOVY_SCRIPT")
      subject.groovy('script')
    end
  end

  describe '#groovy' do
    before { subject.stub(:execute) }

    it 'calls execute' do
      expect(subject).to receive(:execute)
        .with("groovy = <<-GROOVY_SCRIPT\nscript\nGROOVY_SCRIPT")
      subject.groovy('script')
    end
  end
end
