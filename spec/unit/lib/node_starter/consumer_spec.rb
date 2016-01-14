describe NodeStarter::Consumer do
  let(:subject) { NodeStarter::Consumer.new }
  let(:conn) { double(:conn) }
  let(:channel) { double(:channel) }
  let(:dummy_host) { 'foo' }
  let(:dummy_user) { 'guest' }
  let(:dummy_pass) { 'guest' }
  let(:dummy_queue) { 'test-queue' }

  before(:each) do
    allow(conn).to receive(:start)
    allow(conn).to receive(:create_channel).and_return(channel)
    allow(channel).to receive(:queue).with(any_args)
    allow(channel).to receive(:prefetch).with(any_args)

    allow(Bunny).to receive(:new) { conn }
    allow(NodeStarter).to receive_message_chain(:config, :bunny_host).and_return(dummy_host)
    allow(NodeStarter).to receive_message_chain(:config, :bunny_user).and_return(dummy_user)
    allow(NodeStarter).to receive_message_chain(:config, :bunny_password).and_return(dummy_pass)
    allow(NodeStarter).to receive_message_chain(:config, :max_running_uss_nodes).and_return(1)
    allow(NodeStarter).to receive_message_chain(:config, :start_uss_node_queue_name)
      .and_return(dummy_queue)
  end

  describe '#setup' do
    it 'starts listening to specified queue' do
      expect(Bunny).to receive(:new).with(
        hostname: dummy_host,
        username: dummy_user,
        password: dummy_pass
      ) do
        conn
      end

      subject.setup
    end

    it 'starts listening to specified queue' do
      expect(channel).to receive(:queue).with(dummy_queue, any_args)

      subject.setup
    end
  end

  describe '#read' do
    let(:queue) { double(:queue) }

    before(:each) do
      allow(channel).to receive(:queue).and_return(queue)
    end

    it 'fails if queue is not initilized' do
      expect { subject.read }.to raise_error { NodeStarter::Consumer::QueueNotInitialized }
    end

    it 'subscribes to queue' do
      expect(queue).to receive(:name).at_least(:once) { 'test-queue' }
      expect(queue).to receive(:subscribe)

      subject.setup
      subject.subscribe
    end
  end
end
