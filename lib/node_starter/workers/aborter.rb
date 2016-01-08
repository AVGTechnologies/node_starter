require 'sidekiq'
require 'sys/proctable'

module NodeStarter

  class AborterWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'node_aborter', retry: 1

    def perform(node_id)
      node = Node.find(node_id)
      NodeStarter.logger.debug( "abort node=#{node.id} build_id=#{node.build_id}")
	
      process = Sys::ProcTable.ps(node.pid)
      if process.nil?
        NodeStarter.logger.debug( "process to be aborted does not exist node=#{node.id} build_id=#{node.build_id} num_attempts=#{node.abort_attempts}")
        node.killed = true
        node.finished_at = DateTime.now
        node.status = 'finished'
        node.save!
        return
      end
			
      node.abort_attempts = node.abort_attempts + 1
      if node.abort_attempts < 5
        #soft abort
        NodeStarter.logger.debug( "soft abort attempt node=#{node.id} build_id=#{node.build_id} num_attempts=#{node.abort_attempts}")
        Process.kill("HUP", node.pid)
			
      else
        #hard abort
        NodeStarter.logger.debug( "soft abort attempt node=#{node.id} build_id=#{node.build_id} num_attempts=#{node.abort_attempts}")
        Process.kill("INT", node.pid)
      end

      node.save!
      NodeStarter::AborterWorker.perform_in(2.minutes, node_id) 
    end
  end
end
