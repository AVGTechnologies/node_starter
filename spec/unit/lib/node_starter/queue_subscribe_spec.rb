class TestError < StandardError
end

describe NodeStarter::QueueSubscribe do
  let(:subject) { NodeStarter::QueueSubscribe.new }
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
      NodeStarter::QueueSubscribe.new
    end

    it 'creates shutdown consumer' do
      expect(NodeStarter::ShutdownConsumer).to receive :new
      NodeStarter::QueueSubscribe.new
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

    shared_examples_for 'a runner' do |expected_exception|
      def send_run
        subject.send :run, {}, payload.to_json
      end

      def run(exception)
        if exception
          expect { send_run }.to raise_error exception
        else
          send_run
        end
      end

      it 'registers node to shutdown queue' do
        expect(shutdown_consumer).to receive(:register_node).with(payload[:build_id])
        run expected_exception
      end

      it 'unregisters node from shutdown queue' do
        expect(shutdown_consumer).to receive(:unregister_node).with(payload[:build_id])
        run expected_exception
      end

      it 'runs node' do
        expect(starter).to receive :start_node_process
        run expected_exception
      end
    end

    context 'when node starter throws' do
      it_behaves_like 'a runner', TestError

      before do
        starter.stub(:start_node_process) { fail TestError }
      end

      it 'does not acknowledge the message' do
        expect(consumer).to receive(:ack).exactly(0).times
        expect { subject.send :run, {}, '{}' }.to raise_error
      end
    end

    context 'when node starter does not throw' do
      it_behaves_like 'a runner'

      it 'acknowledges the message' do
        expected_delivery_info = 'pizza is here'
        expect(consumer).to receive(:ack).with(expected_delivery_info)
        subject.send :run, expected_delivery_info, '{}'
      end
    end
  end

  describe '#stop' do
    let(:killer) { double('killer') }

    before do
      allow(killer).to receive :shutdown
      allow(NodeStarter::Killer).to receive(:new) { killer }
    end

    context 'when node killer throws' do
      before do
        killer.stub(:shutdown) { fail }
      end

      it 'does not acknowledge the message' do
        expect(shutdown_consumer).to receive(:ack).exactly(0).times
        expect { subject.send :stop, {}, {} }.to raise_error
      end
    end

    context 'when node killer does not throw' do
      it 'acknowledges the message' do
        expected_delivery_info = { routing_key: 'cmd.123' }
        expect(shutdown_consumer).to receive(:ack).with(expected_delivery_info)
        subject.send :stop, expected_delivery_info
      end
    end
  end
end

