require 'bunny'

module NodeStarter
  # class for reporting build state
  class ReportingPublisher
    def setup
      @conn = Bunny.new(
        hostname: NodeStarter.config.rabbit_reporting.host,
        port:     NodeStarter.config.rabbit_reporting.port,
        username: NodeStarter.config.rabbit_reporting.username,
        password: NodeStarter.config.rabbit_reporting.password,
        vhost:    NodeStarter.config.rabbit_reporting.vhost)

      @conn.start

      @channel = @conn.create_channel

      exchange_params = {
        durable: true,
        auto_delete: false
      }

      @exchange = @channel.topic(
        NodeStarter.config.rabbit_reporting.build_reporting_exchange, exchange_params)
    end

    def notify_receive(id)
      @exchange.publish(
        { id: id }.to_json,
        type: NodeStarter.config.amqp.build_receive_message_type || 'build:receive'
      )
    end

    def notify_start(id)
      @exchange.publish(
        { id: id }.to_json,
        type: NodeStarter.config.amqp.build_start_message_type || 'build:start'
      )
    end
  end
end
