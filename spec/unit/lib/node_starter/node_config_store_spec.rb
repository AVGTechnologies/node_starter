require 'rexml/document'
require 'xmlsimple'

describe NodeStarter::NodeConfigStore do
  let(:values) do
    {
      rabbit_logs: {},
      rabbit_reporting: {}
    }
  end

  let(:subject) do
    NodeStarter::NodeConfigStore.new(values)
  end

  let(:dir) do
    Dir.mktmpdir('node_starter_test')
  end

  after(:each) do
    FileUtils.rm_rf(dir)
  end

  describe '#write_to' do
    it 'creates config file' do
      subject.write_to(dir)

      expect(File.exist?("#{dir}/config.xml")).to be true
    end
    it 'replaces value' do
      values['enqueued_by'] = 'tester'

      subject.write_to(dir)

      data = XmlSimple.xml_in(File.read("#{dir}/config.xml"))
      uss_node = data['UssNode']

      expect(uss_node[0]['EnqueuedBy']).to eql(['tester'])
    end
    it 'leaves empty unfilled field' do
      subject.write_to(dir)

      data = XmlSimple.xml_in(File.read("#{dir}/config.xml"))
      uss_node = data['UssNode']
      expect(uss_node[0]['ScenarioInstanceId']).to eql([{}])
    end
  end
end
