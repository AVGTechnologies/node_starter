require 'multi_json'
require 'socket'

require 'node_starter/starter'
require 'node_starter/consumer'
require 'node_starter/shutdown_consumer'

module NodeStarter
  # class for receiving start node messages
  class QueueSubscribe
    def initialize
      @consumer = NodeStarter::Consumer.new
      @shutdown_consumer = NodeStarter::ShutdownConsumer.new
      @reporting_publisher = NodeStarter::ReportingPublisher.new
    end

    def start_listening
      @consumer.setup
      @shutdown_consumer.setup
      @reporting_publisher.setup

      subscribe_stater_queue
      subscribe_killer_queue
    end

    def stop_listening
      NodeStarter.logger.info('Stopping listening. Bye, bye.')
      @consumer.close_connection
      @shutdown_consumer.close_connection
    end

    private

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
      params = JSON.parse(payload)
      NodeStarter.logger.info("Received START with build_id: #{params['build_id']}")
      uuid = SecureRandom.uuid

      starter = NodeStarter::Starter.new(
        params['build_id'],
        params['config'].merge(node_config_extension(uuid)),
        params['enqueue_data'],
        node_api_address(uuid))

      @reporting_publisher.notify_receive(params['build_id'])
      starter.start_node_process
      @shutdown_consumer.register_node(params['build_id'])
      @reporting_publisher.notify_start(params['build_id'])
      wait_for_node(starter, params['build_id'])
    rescue => e
      build_id = params ? params['build_id'] : 'unknown'
      NodeStarter.logger.error "Failed to spawn node with build_id #{build_id}: #{e}"
    ensure
      @consumer.ack(delivery_info)
    end

    def wait_for_node(starter, build_id)
      Thread.new do
        begin
          starter.wait_node_process
        ensure
          @shutdown_consumer.unregister_node(build_id)
        end
      end
    end

    def stop(delivery_info, payload)
      NodeStarter.logger.info("Received kill command: #{delivery_info[:routing_key]}")

      begin
        build_id = delivery_info[:routing_key].to_s
        build_id.slice!('cmd.')

        params = JSON.parse(payload)

        stopped_by = params['stopped_by']

        killer = NodeStarter::Killer.new build_id, stopped_by
        killer.shutdown_by_api
      rescue => e
        NodeStarter.logger.error "Node stop failed: #{e}"
      ensure
        @shutdown_consumer.ack delivery_info
      end

      Thread.new do
        mins = NodeStarter.config.shutdown_node_wait_in_minutes
        NodeStarter.logger.debug(
          "Waiting #{mins} minutes before starting killing node #{build_id}")
        sleep mins.minutes

        killer.watch_process
      end
    end

    def node_config_extension(uuid)
      {
        id: uuid,
        base_address: 'http://' + ip_address + ':8732/AVG.Ddtf.Uss/Node/' + uuid
      }
    end

    def ip_address
      Socket.ip_address_list.detect(&:ipv4_private?).ip_address
    end

    def node_api_address(uuid)
      'http://' + ip_address + ':8732/' + uuid + '/api/'
    end
  end
end
