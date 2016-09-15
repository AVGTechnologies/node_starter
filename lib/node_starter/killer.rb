require 'process_explorer'
require 'node_starter/node_api'
require 'timeout'

module NodeStarter
  # class killing running node process
  class Killer
    class NodeApiNotCalled < RuntimeError
    end

    attr_reader :build_id

    def initialize(build_id, stopped_by)
      @build_id = build_id
      @stopped_by = stopped_by
    end

    def shutdown_by_api
      node = Node.find_by! build_id: @build_id
      @pid = node.pid

      node.update_column :status, :aborting

      shutdown_using_api node.uri
    end

    def watch_process
      fail NodeApiNotCalled, 'Run shutdown by api first' unless @pid
      kill_process if running?
      force_kill_process if running?
    end

    private

    def shutdown_using_api(uri)
      return if uri.to_s.empty?

      NodeStarter.logger.info "Shutting down node using URI #{uri}."
      result = api_response(uri)

      NodeStarter.logger.error "Shutdown failed: #{result.inspect}" unless result.is_a?(Net::HTTPOK)
    end

    def kill_process
      NodeStarter.logger.debug("Checking process #{@pid} of node with build_id #{@build_id}")
      NodeStarter.config.shutdown_node_check_count.times.with_index do |i|
        unless running?
          NodeStarter.logger.debug("Node #{@build_id} finished after #{i} attempts")
          break
        end
        NodeStarter.logger.debug("Node #{@build_id} still alive after #{i + 1} attempts")
        sleep NodeStarter.config.shutdown_node_period_in_minutes.minutes
      end
    end

    def force_kill_process
      NodeStarter.logger.info("Force killing node #{@build_id}")
      Process.kill('KILL', @pid)
    end

    def running?
      ProcessExplorer::Explore.process_exists?(@pid)
    end

    private

    def api_response(uri)
      result = nil
      NodeStarter.config.shutdown_node_api_calls.each do |sleep_time|
        result = NodeApi.new(uri).stop(@stopped_by)
        break if result.is_a?(Net::HTTPOK)
        sleep sleep_time
      end

      result
    end
  end
end
