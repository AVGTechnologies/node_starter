require 'bunny'

module NodeStarter
  # listens for shutdown command
  class ShutdownConsumer
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

      @queue = @channel.queue('', queue_params)
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

      NodeStarter.logger.debug('Waiting for messages in cmd_queue.')
      opts = {
        manual_ack: true,
        block: true
      }

      @queue.subscribe(opts) do |delivery_info, metadata, payload|
        yield delivery_info, metadata, payload
      end
    end

    def ack(delivery_info)
      @channel.ack(delivery_info.delivery_tag)
    end
  end
end
