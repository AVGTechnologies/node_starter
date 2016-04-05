describe NodeStarter::Consumer do
  let(:subject) { NodeStarter::Consumer.new }
  let(:conn) { double(:conn) }
  let(:channel) { double(:channel) }
  let(:dummy_host) { 'foo' }
  let(:dummy_port) { 156_72 }
  let(:dummy_username) { 'guest' }
  let(:dummy_pass) { 'guest' }
  let(:dummy_vhost) { '/' }
  let(:dummy_queue) { 'test-queue' }
  let(:channel_prefetch) { 1 }

  before(:each) do
    allow(conn).to receive(:start)
    allow(conn).to receive(:create_channel).and_return(channel)
    allow(channel).to receive(:queue).with(any_args)
    allow(channel).to receive(:prefetch).with(any_args)

    allow(Bunny).to receive(:new) { conn }
    allow(NodeStarter).to receive_message_chain(:config, :amqp).and_return(
      double(
        'amqp_config',
        host:     dummy_host,
        port:     dummy_port,
        username: dummy_username,
        password: dummy_pass,
        vhost:    dummy_vhost,
        start_uss_node_queue_name: dummy_queue))

    allow(NodeStarter).to receive_message_chain(:config, :max_running_uss_nodes).and_return(1)
    allow(NodeStarter).to receive_message_chain(:config, :uss_node_queue_prefetch)
      .and_return(channel_prefetch)
    allow(NodeStarter).to receive_message_chain(:config, :start_uss_node_queue_name)
      .and_return(dummy_queue)
  end

  describe '#setup' do
    it 'creates connection' do
      expect(Bunny).to receive(:new).with(
        hostname: dummy_host,
        port:     dummy_port,
        username: dummy_username,
        password: dummy_pass,
        vhost:    dummy_vhost
      ) do
        conn
      end

      subject.setup
    end

    it 'creates channel with prefetch' do
      expect(conn).to receive(:create_channel)
      expect(channel).to receive(:prefetch).with(channel_prefetch)

      subject.setup
    end

    it 'connects to queue' do
      expect(channel).to receive(:queue).with(dummy_queue, any_args)

      subject.setup
    end
  end

  describe '#subscribe' do
    let(:queue) { double(:queue) }

    it 'fails if queue is not initilized' do
      expect { subject.subscribe }.to raise_error { NodeStarter::Consumer::QueueNotInitialized }
    end

    it 'subscribes to queue' do
      allow(channel).to receive(:queue).and_return(queue)
      expect(queue).to receive(:name).at_least(:once) { 'test-queue' }
      expect(queue).to receive(:subscribe)

      subject.setup
      subject.subscribe
    end
  end
end
