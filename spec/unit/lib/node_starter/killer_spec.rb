describe NodeStarter::Killer do
  let!(:node) { build :node, build_id: 123, pid: 1, uri: 'foo' }
  let(:subject) { NodeStarter::Killer.new 123, 'stopper' }
  let!(:node_api) { double 'foo' }

  describe '#shutdown_by_api' do
    before do
      allow(NodeStarter::NodeApi).to receive(:new) { node_api }
      allow(node_api).to receive(:stop)
      allow(Node).to receive(:find_by) { node }
      allow(node).to receive(:update_column)
    end

    it 'calls node API' do
      expect(node_api).to receive(:stop) { Net::HTTPOK }
      NodeStarter.config['shutdown_node_api_calls'] = [0]

      subject.shutdown_by_api
    end

    it 'updates node status to aborting' do
      expect(node).to receive(:update_column).with(:status, :aborting)
      subject.shutdown_by_api
    end

    context 'node.uri not specified' do
      before do
        node.uri = nil
      end

      it 'does not use node api at all' do
        expect(NodeStarter::NodeApi).to receive(:new).exactly(0).times
        subject.shutdown_by_api
      end
    end
  end

  describe '#watch_process' do
    before(:each) do
      subject.send :instance_variable_set, '@pid', 1
      allow(subject).to receive(:sleep)
      NodeStarter.config['shutdown_node_check_count'] = 2
      NodeStarter.config['shutdown_node_period_in_minutes'] = 1
    end

    it 'fails if node api was not called first' do
      subject.send :instance_variable_set, '@pid', nil
      expect { subject.watch_process }.to raise_error { NodeStarter::Killer::NodeApiNotCalled }
    end

    it 'checks process for specified times' do
      responses = []
      NodeStarter.config.shutdown_node_check_count.times do
        responses << true
      end

      expect(ProcessExplorer::Explore).to receive(:process_exists?).and_return(
        true,
        *responses,
        nil
      )

      expect(Process).to receive(:kill).with('KILL', 1).exactly(0).times
      subject.watch_process
    end

    it 'doesn\'t force kill process if finishes' do
      allow(ProcessExplorer::Explore).to receive(:process_exists?) { nil }
      expect(Process).to receive(:kill).with('KILL', 1).exactly(0).times
      subject.watch_process
    end

    it 'force kills process' do
      allow(ProcessExplorer::Explore).to receive(:process_exists?) { true }
      expect(Process).to receive(:kill).with('KILL', 1).exactly(1).times
      subject.watch_process
    end
  end
end
