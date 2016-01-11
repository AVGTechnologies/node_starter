describe NodeStarter::Models::Node do
  let(:subject) { NodeStarter::Models::Node.new }

  describe 'after_create hook' do
    it 'sends build_id to subscribers' do
      subject.build_id = 123
      notification_build_id = nil
      subscription = ActiveSupport::Notifications.subscribe('node.created') do |*_, payload|
        notification_build_id = payload[:build_id]
      end
      subject.run_callbacks(:create)
      expect(notification_build_id).to eq subject.build_id
      ActiveSupport::Notifications.unsubscribe(subscription)
    end
  end
end
