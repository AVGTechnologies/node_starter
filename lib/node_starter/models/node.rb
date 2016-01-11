require 'active_model'
require 'active_model/validations'
# == Schema Information
#
# Table name: nodes
#
#  id             :integer          not null, primary key
#  build_id       :integer
#  pid            :integer          default(-1)
#  started_at     :datetime
#  finished_at    :datetime
#  aborted_at     :datetime
#  status         :string
#  abort_attempts :integer
#  killed         :boolean
#  path           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

module NodeStarter::Models
  # represents a single build
  class Node < ActiveRecord::Base
    after_create :notify_created

    private

    def notify_created
      ActiveSupport::Notifications.instrument('node.created', build_id: build_id)
    end
  end
end
