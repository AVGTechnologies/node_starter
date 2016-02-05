require 'bunny'

module NodeStarter
  # class wrapping connection to queue that stores uss nodes to be started
  class Consumer
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
      @channel.prefetch(NodeStarter.config.uss_node_queue_prefetch)

      queue_params = {
        durable: true,
        auto_delete: false
      }
      @queue = @channel.queue(NodeStarter.config.start_uss_node_queue_name, queue_params)
    end

    def subscribe
      fail QueueNotInitialized unless @queue

      NodeStarter.logger.debug("Waiting for messages in #{@queue.name}.")
      opts = {
        manual_ack: true,
        block: false
      }
      @queue.subscribe(opts) do |delivery_info, metadata, payload|
        yield delivery_info, metadata, payload
      end
    end

    def close_connection
      @channel.close
    end

    def ack(delivery_info)
      @channel.ack(delivery_info.delivery_tag)
    end

    def reject(delivery_info, requeue)
      @channel.reject(delivery_info.delivery_tag, requeue)
    end
  end
end
