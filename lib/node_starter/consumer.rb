require 'bunny'

module NodeStarter
  # class wrapping connection to queue that stores uss nodes to be started
  class Consumer
    class QueueNotInitilized < StandardError
    end

    def setup
      @conn = Bunny.new(hostname: NodeStarter.config.bunny_host)
      @conn.start

      @channel = @conn.create_channel
      @queue = @channel.queue(NodeStarter.config.queue_name)
    end

    def subscribe
      fail QueueNotInitilized unless @queue

      NodeStarter.logger.debug("Waiting for messages in #{@queue.name}.")

      @queue.subscribe(ack: true, block: true) do |delivery_info, metadata, payload|
        yield delivery_info, metadata, payload
      end
    end

    def ack(delivery_info)
      @channel.ack(delivery_info.delivery_tag)
    end
  end
end
