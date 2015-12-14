require 'multi_json'

require 'node_starter/starter'
require 'node_starter/consumer'

module NodeStarter
  # class for receiving start node messages
  class QueueSubscribe
    def initialize
      @consumer = NodeStarter::Consumer.new
    end

    def start_listening
      @consumer.setup

      @consumer.subscribe do |delivery_info, metadata, payload|
        NodeStarter.logger.debug("Received #{payload} with metadata #{metadata.inspect}")

        params = parse(payload)

        starter = NodeStarter::Starter.new(
          params['build_id'], params['config'], params['enqueue_data'])

        starter.schedule_spawn_process

        @consumer.ack(delivery_info)
      end
    end

    def close_connection
      @consumer.close_connection
    end

    def parse(json_body)
      JSON.parse(json_body)
    end
  end
end
