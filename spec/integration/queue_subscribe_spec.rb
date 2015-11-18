require 'json'

describe 'NodeStarter::Subscribe integration' do
  let(:subject) { NodeStarter::QueueSubscribe.new }
  let(:sender) { NodeStarter::MessageSender.new }

  it 'starts node process' do
    expect_any_instance_of(NodeStarter::Starter)
      .to receive(:start).with(any_args).and_return(111)

    subject.start_listening

    message = {
      build_id: '123456',
      config: {},
      enqueue_data: '<xml>enqueue_data</xml>'
    }
    sender.send_message(message.to_json)
    sleep 1
  end
end
