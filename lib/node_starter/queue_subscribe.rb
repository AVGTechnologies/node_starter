require 'multi_json'

require 'node_starter/starter'
require 'node_starter/consumer'
require 'node_starter/shutdown_consumer'

module NodeStarter
  # class for receiving start node messages
  class QueueSubscribe
    def initialize
      @consumer = NodeStarter::Consumer.new
      @shutdown_consumer = NodeStarter::ShutdownConsumer.new
    end

    def start_listening
      @consumer.setup
      @shutdown_consumer.setup

      subscribe_stater_queue
      subscribe_killer_queue
    end

    def stop_listening
      @consumer.close_connection
      @shutdown_consumer.close_connection
    end

    private

    def parse(json_body)
      JSON.parse(json_body)
    end

    def subscribe_stater_queue
      @consumer.subscribe do |delivery_info, _metadata, payload|
        run delivery_info, payload
      end
    end

    def subscribe_killer_queue
      @shutdown_consumer.subscribe do |delivery_info, _metadata, payload|
        stop delivery_info, payload
      end
    end

    def run(delivery_info, payload)
      params = parse(payload)
      NodeStarter.logger.debug("Received START with build_id: #{params['build_id']}")
      # config and enqueue_data as raw xml
      # TODO: make a better payload model
      starter = NodeStarter::Starter.new(
        params['build_id'], params['config'], params['enqueue_data'], params['node_api_uri'])

      @shutdown_consumer.register_node(params['build_id'])

      begin
        starter.start_node_process
      rescue => e
        NodeStarter.logger.error e
        raise e
      ensure
        @shutdown_consumer.unregister_node(params['build_id'])
      end

      @consumer.ack(delivery_info)
    end

    def stop(delivery_info)
      NodeStarter.logger.debug("Received kill command: #{delivery_info[:routing_key]}")

      build_id = delivery_info[:routing_key].to_s.slice('cmd.')

      killer = NodeStarter::Killer.new build_id
      killer.shutdown

      @shutdown_consumer.ack delivery_info
    end
  end
end
