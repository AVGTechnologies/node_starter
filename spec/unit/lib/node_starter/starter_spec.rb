describe NodeStarter::Starter do
  let(:subject) do
    NodeStarter::Starter.new('123', {}, {}, 'node_api_uri', 'environment_name')
  end
  let(:tmp_dir) { '/tmpdir' }

  before(:each) do
    allow(NodeStarter.config).to receive_message_chain(:uss_node, :merge) { {} }
    allow(NodeStarter.config).to receive_message_chain(:uss_node, :logs_storage_path) { '/logs' }
  end

  describe '#start_node_process' do
    let(:config_data) { double(:status) }
    let(:fake_node) { build :node, path: 'bar', build_id: 123 }

    before(:each) do
      allow(NodeStarter::PrepareBinaries).to receive(:write_to)
      allow_any_instance_of(NodeStarter::NodeConfigStore).to receive(:write_to)
      allow(NodeStarter::EnqueueDataStore).to receive(:write_to)
      allow(Process).to receive(:spawn) { 123 }

      allow(Node).to receive(:create!) { fake_node }
      allow(fake_node).to receive(:update_column)
      allow(fake_node).to receive(:update_column)
      allow(Dir).to receive(:mktmpdir) { tmp_dir }
      allow(File).to receive(:exist?)
      allow(FileUtils).to receive(:cp)

      allow(NodeStarter.config).to receive_message_chain(:uss_node, :node_binary_name) do
        'binary_name'
      end
    end

    it 'prepares binaries' do
      expect(NodeStarter::PrepareBinaries).to receive(:write_to)
      subject.start_node_process
    end

    it 'prepares config' do
      expect_any_instance_of(NodeStarter::NodeConfigStore).to receive(:write_to)
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

    it 'starts node process' do
      expect(Process).to receive(:spawn) { 123 }
      subject.start_node_process
    end

    it 'updates pid in db' do
      expect(fake_node.pid).to be(-1)
      expected_pid = 123
      expect(Process).to receive(:spawn) { expected_pid }
      expect(fake_node).to receive(:update_column).with(:pid, expected_pid)

      subject.start_node_process
    end

    it 'updates status to running' do
      expect(fake_node).to receive(:update_column).with(:status, :running)

      subject.start_node_process
    end
  end

  describe '#wait_node_process' do
    let(:running_fake_node) { build :node, path: 'bar', build_id: 123, pid: 1 }

    before(:each) do
      allow(Process).to receive(:wait)
      allow(Node).to receive(:find_by!) { running_fake_node }
      allow(running_fake_node).to receive(:update_column).with(:status, :finished)

      subject.send :instance_variable_set, '@pid', 1
      subject.send :instance_variable_set, '@dir', tmp_dir
    end

    it 'waits for node process' do
      expect(Process).to receive(:wait)
      subject.wait_node_process
    end

    it 'copies log file to artifact storage' do
      expect(File).to receive(:exist?) { true }
      expected_source = '/tmpdir/debug.log'
      expected_target = "/logs/#{running_fake_node.build_id}.log"
      expect(FileUtils).to receive(:cp).with(expected_source, expected_target)

      subject.wait_node_process
    end

    it 'deletes working folder after test' do
      expect(FileUtils).to receive(:rm_rf).with tmp_dir
      subject.wait_node_process
    end

    it 'updates status to finished' do
      expect(running_fake_node).to receive(:update_column).with(:status, :finished)
      subject.wait_node_process
    end
  end
end
