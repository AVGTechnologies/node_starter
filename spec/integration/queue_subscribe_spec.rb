require 'json'

# Fake consumer to avoid usage of RabbitMQ
class FakeConsumer
  def setup
  end

  def subscribe(&block)
    @block = block
  end

  def call(*args)
    @block.call(*args)
  end

  def ack(_delivery_info)
    {}
  end
end

describe 'NodeStarter::Subscribe integration' do
  let(:subject) { NodeStarter::QueueSubscribe.new }
  # let(:sender) { NodeStarter::MessageSender.new }
  let(:fake_consumer) { FakeConsumer.new }

  it 'starts node process' do
    expect(NodeStarter::Consumer).to receive(:new) { fake_consumer }
    allow(NodeStarter::PrepareBinaries).to receive(:write_to)

    expect_any_instance_of(NodeStarter::Starter)
      .to receive(:start).with(any_args).and_return(111)

    subject.start_listening

    message = {
      build_id: '123456',
      config: {},
      enqueue_data: '<xml>enqueue_data</xml>'
    }

    fake_consumer.call(nil, nil, message.to_json)
    sleep 1
  end
end
