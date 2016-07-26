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
      build_reporting_exchange: 'qux',
      build_reporting_routing_key: 'mio',
      build_receive_message_type: 'receive'
    }
  end

  let(:config) do
    double('config', amqp: double('amqp', fake_config))
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
        hostname: config.amqp.host,
        port:     config.amqp.port,
        username: config.amqp.username,
        password: config.amqp.password,
        vhost:    config.amqp.vhost
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
end
