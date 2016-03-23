require 'bunny'

module NodeStarter
  # class representing message sender to rabbit MQ
  class MessageSender
    def initialize
      @conn = Bunny.new(hostname: NodeStarter.config.amqp.host)
      @queue = nil
    end

    def send_message(message = 'Hello World!')
      @conn.start

      @channel = @conn.create_channel
      queue_params = {
        durable: true,
        auto_delete: false
      }
      @queue = @channel.queue(NodeStarter.config.amqp.start_uss_node_queue_name, queue_params)

      @channel.default_exchange.publish(message, routing_key: @queue.name)
    end
  end
end
