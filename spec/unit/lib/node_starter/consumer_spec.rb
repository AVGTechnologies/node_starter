describe NodeStarter::Consumer do
  let(:subject) { NodeStarter::Consumer.new }
  let(:conn) { double(:conn) }
  let(:channel) { double(:channel) }
  let(:dummy_host) { 'foo' }
  let(:dummy_queue) { 'test-queue' }

  before(:each) do
    allow(conn).to receive(:start)
    allow(conn).to receive(:create_channel).and_return(channel)

    allow(Bunny).to receive(:new) { conn }
    allow(NodeStarter).to receive_message_chain(:config, :bunny_host).and_return(dummy_host)
    allow(NodeStarter).to receive_message_chain(:config, :queue_name).and_return(dummy_queue)
  end

  describe '#setup' do
    it 'starts listening to specified queue' do
      expect(Bunny).to receive(:new).with(hostname: dummy_host) { conn }
      allow(channel).to receive(:queue)

      subject.setup
    end

    it 'starts listening to specified queue' do
      expect(channel).to receive(:queue).with(dummy_queue)

      subject.setup
    end
  end

  describe '#read' do
    let(:queue) { double(:queue) }

    before(:each) do
      allow(channel).to receive(:queue).and_return(queue)
    end

    it 'fails if queue is not initilized' do
      expect { subject.read }.to raise_error { NodeStarter::Consumer::QueueNotInitilized }
    end

    it 'subscribes to queue' do
      expect(queue).to receive(:name) { 'test-queue' }
      expect(queue).to receive(:subscribe)

      subject.setup
      subject.subscribe
    end
  end

  describe '#close_connection' do
    it 'raises error without setup' do
      expect { subject.close_connection }.to raise_error { NoMethodError }
    end
  end
end
