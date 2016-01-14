describe NodeStarter::NodeApi do
  let(:base_uri) { URI('http://foo:1234/api/') }
  let(:subject) { NodeStarter::NodeApi.new base_uri }

  describe '#stop' do
    it 'resolves correct host' do
      expect(Net::HTTP).to receive(:start)
        .with(base_uri.hostname, base_uri.port)
      subject.stop 'goldilocks'
    end

    it 'resolves correct address' do
      request = double(:request)
      expected_uri = 'http://foo:1234/api/v2/shutdown'
      request = double(:request)
      allow(request).to receive :body=
      expect(Net::HTTP).to receive(:start)
      expect(Net::HTTP::Post).to receive(:new) do |uri, _|
        expect(uri.to_s).to eq expected_uri
        request
      end
      subject.stop 'goldilocks'
    end

    it 'sends stopped_by in request body' do
      http = double(:http)
      expect(http).to receive(:request) do |request|
        stopped_by = JSON.parse(request.body)['stopped_by']
        expect(stopped_by).to eq 'Goldilocks'
      end
      expect(Net::HTTP).to receive(:start).and_yield(http)
      subject.stop 'Goldilocks'
    end
  end
end
