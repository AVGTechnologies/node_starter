require 'sidekiq'

module NodeStarter

  class StarterWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'node_starter', retry: 1

    def perform(node_id)
      node = Node.find(node_id)
      p "starting node: #{node}"
    end
  end
end