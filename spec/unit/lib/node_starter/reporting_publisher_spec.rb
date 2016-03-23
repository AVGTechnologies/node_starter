describe NodeStarter::ReportingPublisher do
  let(:subject) { NodeStarter::ReportingPublisher.new }
  let(:connection) { double(:connection) }
  let(:channel) { double(:channel) }
  let(:topic) { double(:topic, publish: {}) }
  let(:fake_config) do
    {
      host: 'foo',
      port: 123_456,
      username: 'neo',
      password: 'bar',
      vhost: 'baz',
      build_reporting_exchange: 'qux'
    }
  end

  let(:config) do
    double('config',
           rabbit_reporting: double('rabbit', fake_config),
           amqp: double('amqp', build_receive_message_type: {}, build_start_message_type: {}))
  end

  before do
    allow(connection).to receive(:start)
    allow(connection).to receive(:create_channel) { channel }
    allow(channel).to receive(:topic).with(any_args) { topic }
    allow(NodeStarter).to receive(:config) { config }
    allow(Bunny).to receive(:new) { connection }
  end

  describe '#setup' do
    it 'starts connection to rabbit' do
      bunny_configuration_expect = {
        hostname: config.rabbit_reporting.host,
        port:     config.rabbit_reporting.port,
        username: config.rabbit_reporting.username,
        password: config.rabbit_reporting.password,
        vhost:    config.rabbit_reporting.vhost
      }

      expect(Bunny).to receive(:new).with(bunny_configuration_expect) { connection }
      subject.setup
    end

    it 'creates an exchange for reporting' do
      expect(channel).to receive(:topic)
      subject.setup
    end
  end

  describe '#notify_receive' do
    it 'publishes receive message' do
      expect(topic).to receive(:publish)
      subject.setup
      subject.notify_receive('19')
    end
  end

  describe '#notify_start' do
    it 'publishes start message' do
      expect(topic).to receive(:publish)
      subject.setup
      subject.notify_start('19')
    end
  end
end
