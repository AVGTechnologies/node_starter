class TestError < StandardError
end

describe NodeStarter::QueueSubscribe do
  let(:subject) { NodeStarter::QueueSubscribe.new('environment_name') }
  let(:consumer) do
    double('consumer',
           setup: {},
           subscribe: {},
           close_connection: {})
  end
  let(:shutdown_consumer) do
    double('shutdown_consumer',
           setup: {},
           subscribe: {},
           close_connection: {})
  end

  before do
    allow(NodeStarter::Consumer).to receive(:new) { consumer }
    allow(NodeStarter::ShutdownConsumer).to receive(:new) { shutdown_consumer }
  end

  describe '#initialize' do
    it 'creates starter consumer' do
      expect(NodeStarter::Consumer).to receive :new
      NodeStarter::QueueSubscribe.new('environment_name')
    end

    it 'creates shutdown consumer' do
      expect(NodeStarter::ShutdownConsumer).to receive :new
      NodeStarter::QueueSubscribe.new('environment_name')
    end
  end

  describe '#start_listening' do
    it 'sets consumer up' do
      expect(consumer).to receive :setup
      subject.start_listening
    end

    it 'sets shutdown_consumer up' do
      expect(shutdown_consumer).to receive :setup
      subject.start_listening
    end

    it 'subscribes to starter queue' do
      expect(consumer).to receive :subscribe
      subject.start_listening
    end

    it 'subscribes to shutdown queue' do
      expect(shutdown_consumer).to receive :subscribe
      subject.start_listening
    end
  end

  describe '#stop_listening' do
    it 'closes consumer connection' do
      expect(consumer).to receive :close_connection
      subject.stop_listening
    end

    it 'closes cmd consumer connection' do
      expect(shutdown_consumer).to receive :close_connection
      subject.stop_listening
    end
  end

  describe 'close_connection' do
    it 'raises error without setup' do
      expect { subject.close_connection }.to raise_error { NoMethodError }
    end
  end

  describe '#run' do
    let(:payload) { { build_id: 123 } }
    let(:starter) { double('starter') }

    before do
      allow(consumer).to receive :ack
      allow(shutdown_consumer).to receive :unregister_node
      allow(shutdown_consumer).to receive :register_node
      allow(NodeStarter::Starter).to receive(:new) { starter }
      allow(starter).to receive :start_node_process
    end

    context 'when node starter throws' do
      before do
        allow(starter).to receive(:start_node_process) { fail TestError }
      end

      it 'does not acknowledge and rejects the message' do
        expect(consumer).to receive(:ack).exactly(0).times
        expect(consumer).to receive(:reject).exactly(1).times
        subject.send :run, {}, '{}'
      end
    end

    context 'when node starter does not throw' do
      def send_run(delivery_info = '')
        subject.send :run, delivery_info, payload.to_json
      end

      it 'registers node to shutdown queue' do
        expect(shutdown_consumer).to receive(:register_node).with(payload[:build_id])
        send_run
        sleep 0.1
      end

      it 'unregisters node from shutdown queue' do
        expect(shutdown_consumer).to receive(:unregister_node).with(payload[:build_id])
        send_run
        sleep 0.1
      end

      it 'runs node' do
        expect(starter).to receive :start_node_process
        send_run
        sleep 0.1
      end

      it 'acknowledges the message' do
        expected_delivery_info = 'pizza is here'
        expect(consumer).to receive(:ack).with(expected_delivery_info)
        send_run(expected_delivery_info)
        sleep 0.1
      end

      it 'sends nack on invalid input' do
        expect(consumer).to receive(:reject).exactly(1).times
        subject.send :run, {}, '{'
        sleep 0.1
      end
    end
  end

  describe '#stop' do
    let(:killer) { double('killer') }
    let(:expected_delivery_info) do
      { routing_key: 'cmd.123' }
    end

    before do
      allow(killer).to receive :shutdown_by_api
      allow(NodeStarter::Killer).to receive(:new) { killer }
    end

    context 'when node killer does not throw' do
      it 'acknowledges the message' do
        expect(shutdown_consumer).to receive(:ack).with(expected_delivery_info)

        subject.send(:stop, expected_delivery_info, { 'stopped_by' => 'stopper' }.to_json)
        sleep 0.1
      end

      it 'parses build_id' do
        expect(shutdown_consumer).to receive(:ack).with(expected_delivery_info)
        expect(NodeStarter::Killer).to receive(:new).with('123', anything) { killer }

        subject.send(:stop, expected_delivery_info, { 'stopped_by' => 'stopper' }.to_json)
        sleep 0.1
      end

      it 'parses stooped_by' do
        expect(shutdown_consumer).to receive(:ack).with(expected_delivery_info)
        expect(NodeStarter::Killer).to receive(:new).with(anything, 'stopper') { killer }

        subject.send(:stop, expected_delivery_info, { 'stopped_by' => 'stopper' }.to_json)
        sleep 0.1
      end

      it 'sends nack on invalid input' do
        expect(shutdown_consumer).to receive(:reject).exactly(1).times

        subject.send(:stop, expected_delivery_info, '{')
        sleep 0.1
      end
    end
  end
end
