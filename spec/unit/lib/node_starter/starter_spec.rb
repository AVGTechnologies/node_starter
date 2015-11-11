describe NodeStarter::Starter do
  let(:subject) do
    NodeStarter::Starter.new('1', {}, nil)
  end

  before(:each) do
    allow(subject).to receive(:start).and_return(0)
  end

  describe '#spawn_process' do
    it 'prepares binaries' do
      allow(NodeStarter::PrepareBinaries).to receive(:write_to)
      subject.spawn_process
      FileUtils.rm_rf(subject.dir)
    end
    it 'prepares config' do
      allow_any_instance_of(NodeStarter::NodeConfigStore).to receive(:write_to)
      subject.spawn_process
      FileUtils.rm_rf(subject.dir)
    end
    it 'prepares enqueue data' do
      allow(NodeStarter::EnqueueDataStore).to receive(:write_to)
      subject.spawn_process
      FileUtils.rm_rf(subject.dir)
    end
    it 'returns exit code 0' do
      expect(subject.spawn_process).to eq(0)
      FileUtils.rm_rf(subject.dir)
    end
  end
end
