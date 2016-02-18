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
      NodeStarter.logger.info('Stopping listening. Bye, bye.')
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
      NodeStarter.logger.info("Received START with build_id: #{params['build_id']}")
      # config and enqueue_data as raw xml
      # TODO: make a better payload model
      starter = NodeStarter::Starter.new(
        params['build_id'], params['config'], params['enqueue_data'], params['node_api_uri'])

      begin
        starter.start_node_process
        @consumer.ack(delivery_info)
        @shutdown_consumer.register_node(params['build_id'])
      rescue => e
        NodeStarter.logger.error "Node #{params['build_id']} spawn failed: #{e}"
        @consumer.reject(delivery_info, true)
        return
      end

      Thread.new do
        begin
          starter.wait_node_process
        ensure
          @shutdown_consumer.unregister_node(params['build_id'])
        end
      end
    end

    def stop(delivery_info, payload)
      NodeStarter.logger.info("Received kill command: #{delivery_info[:routing_key]}")

      build_id = delivery_info[:routing_key].to_s
      build_id.slice!('cmd.')

      params = parse(payload)

      stopped_by = params['stopped_by']

      killer = NodeStarter::Killer.new build_id, stopped_by
      killer.shutdown_by_api
      @shutdown_consumer.ack delivery_info

      Thread.new do
        mins = NodeStarter.config.shutdown_node_wait_in_minutes
        NodeStarter.logger.debug(
          "Waiting #{mins} minutes before starting killing node #{build_id}")
        sleep mins.minutes

        killer.watch_process
      end
    end
  end
end
