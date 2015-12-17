require 'bunny'

module NodeStarter
  class CmdConsumer
	
    class QueueNotInitialized < StandardError
    end

    def setup
      @conn = Bunny.new(
        hostname: NodeStarter.config.bunny_host,
        username: NodeStarter.config.bunny_user,
        password: NodeStarter.config.bunny_password
      )
      @conn.start

      @channel = @conn.create_channel
      @exchange = @channel.direct(NodeStarter.config.stop_uss_node_queue_name)

      queue_params = {
        durable: false,
        auto_delete: true,
        exclusive: true
      }

      @queue = @channel.queue("", queue_params)
    end

    def register_node(build_id)
      fail QueueNotInitialized unless @queue
      NodeStarter.logger.debug("Registering node build_id=#{build_id} to receive commands")
      @queue.bind(@exchange, routing_key: "cmd.#{build_id}")
    end

    def unregister_node(build_id)
      fail QueueNotInitialized unless @queue
      NodeStarter.logger.debug("Unregistering node build_id=#{build_id} to receive commands")
      @queue.unbind(@exchange, routing_key: "cmd.#{build_id}")
    end

    def subscribe
      fail QueueNotInitialized unless @queue

      NodeStarter.logger.debug("Waiting for messages in cmd_queue.")
      opts = {
        manual_ack: true,
        block: true
      }

      @queue.subscribe(opts) do |delivery_info, metadata, payload|
        handle_cmd delivery_info, metadata, payload
      end
    end

    private

    def handle_cmd(delivery_info, metadata, payload)
      data = JSON.parse(payload).to_hash
      build_id = delivery_info[:routing_key].to_s.gsub(/^cmd\./,'')
      handle_kill(build_id) if data['cmd'] == 'kill'
      @channel.ack(delivery_info.delivery_tag)
    end

    def handle_kill(id)
      # schedule sidekiq job
      Node.where(build_id: id).each do |n|
        n.abort_attempts = 1 + n.abort_attempts || 0
        n.aborted_at = DateTime.now
        n.save!
        NodeStarter.logger.debug("Scheduling node=#{n.id} with build_id=#{id} to be killed")
        NodeStarter::AborterWorker.perform_async(n.id) 
      end
    end
  end
end
