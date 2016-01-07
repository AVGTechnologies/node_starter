describe NodeStarter::PrepareBinaries do
  context 'node_binaries_path does not exist' do
    describe '#write_to' do
      it 'fails with an error message' do
        expect(File).to receive(:directory?) { false }
        message = 'Configured node_binaries_path is not a directory.'
        expect { NodeStarter::PrepareBinaries.write_to('bad_path') }.to raise_error message
      end
    end
  end
end
