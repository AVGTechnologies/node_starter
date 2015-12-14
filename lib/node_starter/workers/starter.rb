require 'sidekiq'

module NodeStarter

  class StarterWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'node_starter', retry: 1

    def perform(node_id)
      node = Node.find(node_id)
      raise 'Executable is already running' unless node.pid == -1
      NodeStarter.logge.debug( "starting node: #{node}")
      dir = node.path
      node_executable_path = File.join(dir, NodeStarter.config.node_binary_name)

      command = "#{node_executable_path} --start -e #{dir}/enqueueData.bin -c #{dir}/config.xml"
      pid = Process.spawn({}, command)

      NodeStarter.logger.info("Node #{node.build_id} spawned in #{dir} with pid #{pid}")

      node.status = :running
      node.pid = pid
      node.save!
    end
  end
end
