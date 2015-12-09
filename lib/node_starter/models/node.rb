require 'active_model'
require 'active_model/validations'

# == Schema Information
#
# Table name: nodes
#
#  id             :integer          not null, primary key
#  build_id       :integer
#  pid            :integer
#  started_at     :datetime
#  finished_at    :datetime
#  aborted_at     :datetime
#  status         :string
#  abort_attempts :integer
#  killed         :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Node < ActiveRecord::Base
end
