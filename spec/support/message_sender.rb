require 'bunny'

module NodeStarter
  # class representing message sender to rabbit MQ
  class MessageSender
    def initialize
      @conn = Bunny.new(hostname: NodeStarter.config.bunny_host)
      @queue = nil
    end

    def send_message(message = 'Hello World!')
      @conn.start

      @channel = @conn.create_channel
      @queue = @channel.queue(NodeStarter.config.queue_name)

      @channel.default_exchange.publish(message, routing_key: @queue.name)
    end
  end
end
