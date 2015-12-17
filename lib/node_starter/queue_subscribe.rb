require 'multi_json'

require 'node_starter/starter'
require 'node_starter/consumer'
require 'node_starter/cmd_consumer'

module NodeStarter
  class QueueSubscribe
    def initialize
      @consumer = NodeStarter::Consumer.new
      @cmd_consumer = NodeStarter::CmdConsumer.new
    end

    def start_listening
      @consumer.setup
      @cmd_consumer.setup
			
      @consumer.subscribe do |delivery_info, metadata, payload|
        NodeStarter.logger.debug("Received #{payload} with metadata #{metadata.inspect}")

        params = parse(payload)

        starter = NodeStarter::Starter.new(
          params['build_id'], params['config'], params['enqueue_data'])

        starter.schedule_spawn_process
				
        #reserve return queue for receiving commands
        @cmd_consumer.register_node(params['build_id'])

        @consumer.ack(delivery_info)
      end

      Node.where(status: 'running').each {|n| @cmd_consumer.register_node(n.build_id)}
      @cmd_consumer.subscribe
    end

    def close_connection
      @consumer.close_connection
    end

    def parse(json_body)
      JSON.parse(json_body)
    end
  end
end
