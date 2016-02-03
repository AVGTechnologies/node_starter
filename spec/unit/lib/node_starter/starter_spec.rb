describe NodeStarter::Starter do
  let(:subject) do
    NodeStarter::Starter.new('123', {}, {}, 'node_api_uri')
  end

  let(:fake_node) { build :node, path: 'bar', build_id: 123 }

  describe '#start_node_process' do
    before(:each) do
      allow(NodeStarter::PrepareBinaries).to receive(:write_to)
      allow(NodeStarter::NodeConfigStore).to receive(:write_complete_file)
      allow(NodeStarter::EnqueueDataStore).to receive(:write_to)
      allow(Process).to receive(:spawn) { 123 }
      allow(Process).to receive(:wait)
      allow(Node).to receive(:create!) { fake_node }
      allow(Dir).to receive(:mktmpdir) { '/tmpdir' }
      allow(File).to receive(:exist?)
      allow(FileUtils).to receive(:cp)
      allow(fake_node).to receive(:save!)
      NodeStarter.config['uss_node']['logs_storage_path'] = '/logs'
      NodeStarter.config['node_binary_name'] = 'binary_name'
    end

    it 'prepares binaries' do
      expect(NodeStarter::PrepareBinaries).to receive(:write_to)
      subject.start_node_process
    end

    it 'prepares config' do
      expect(NodeStarter::NodeConfigStore).to receive(:write_complete_file)
      subject.start_node_process
    end

    it 'prepares enqueue data' do
      allow(subject).to receive(:start).and_return(0)
      expect(NodeStarter::EnqueueDataStore).to receive(:write_to)
      subject.start_node_process
    end

    it 'creates node record in db' do
      expect(Node).to receive(:create!) { fake_node }
      subject.start_node_process
    end

    it 'starts and waits for node process' do
      expect(Process).to receive(:spawn) { 123 }
      expect(Process).to receive(:wait)
      subject.start_node_process
    end

    it 'copies log file to artifact storage' do
      expect(Dir).to receive(:mktmpdir) { '/tmpdir' }
      expect(File).to receive(:exist?) { true }
      expected_source = '/tmpdir/debug.log'
      expected_target = "/logs/#{fake_node.build_id}.log"
      expect(FileUtils).to receive(:cp).with(expected_source, expected_target)
      subject.start_node_process
    end

    it 'deletes working folder after test' do
      expected_dir = 'foo/bar'
      expect(Dir).to receive(:mktmpdir) { expected_dir }
      expect(FileUtils).to receive(:rm_rf).with expected_dir
      subject.start_node_process
    end

    it 'updates pid in db' do
      expect(fake_node.pid).to be(-1)
      expected_pid = 123
      expect(Process).to receive(:spawn) { expected_pid }
      expect(fake_node).to receive(:save!)
      expect(fake_node).to receive(:save!) do
        expect(fake_node.pid).to eq expected_pid
      end
      subject.start_node_process
    end

    it 'updates status to running' do
      expect(fake_node).to receive(:save!)
      expect(fake_node).to receive(:save!) do
        expect(fake_node.status).to eq 'running'
      end
      subject.start_node_process
    end

    it 'updates status to finished' do
      expect(fake_node).to receive(:save!).twice
      expect(fake_node).to receive(:save!) do
        expect(fake_node.status).to eq 'finished'
      end
      subject.start_node_process
    end
  end
end
