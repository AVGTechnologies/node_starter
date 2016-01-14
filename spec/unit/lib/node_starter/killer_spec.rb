describe NodeStarter::Killer do
  let!(:node) { build :node, build_id: 123, pid: 1, uri: 'foo' }
  let(:subject) { NodeStarter::Killer.new 123 }
  let!(:node_api) { double 'foo' }

  describe '#shutdown' do

    before do
      allow(subject). to receive(:sleep) { puts 'sleep' }
      allow(NodeStarter::NodeApi).to receive(:new) { node_api }
      allow(node_api).to receive(:stop)
      allow(Node).to receive(:find_by) { node }
      allow(Process).to receive(:kill)
      allow(node).to receive(:update_column)
      allow(Process).to receive(:wait)
    end

    shared_examples 'a killer' do
      it 'updates node record status to aborting' do
        expect(node).to receive(:update_column).with :status, :aborting
        subject.shutdown
      end
    end

    shared_examples 'a process killer' do
      it 'kills node process' do
        expect(Process).to receive(:kill).with('INT', 1).exactly(5).times
        expect(Process).to receive(:kill).with('KILL', 1).exactly(1).times
        subject.shutdown
      end
    end

    context 'node api shutdown works' do
      before do
        allow(Sys::ProcTable).to receive(:ps) { nil }
      end

      it 'stops node using api' do
        expect(node_api).to receive(:stop) { Net::HTTPSuccess }
        subject.shutdown
      end

      it_behaves_like 'a killer'
    end

    context 'node api shutdown does not work' do
      before do
        allow(Sys::ProcTable).to receive(:ps) { true }
      end

      it_behaves_like 'a killer'
      it_behaves_like 'a process killer'
    end

    context 'node.uri not specified' do
      before do
        node.uri = nil
        allow(Sys::ProcTable).to receive(:ps) { true }
      end

      it 'does not use node api at all' do
        expect(NodeStarter::NodeApi).to receive(:new).exactly(0).times
        subject.shutdown
      end

      it_behaves_like 'a killer'
      it_behaves_like 'a process killer'
    end
  end
end
