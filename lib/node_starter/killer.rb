require 'sys/proctable'
require 'node_starter/node_api'
require 'timeout'

module NodeStarter
  # class killing running node process
  class Killer
    attr_reader :build_id

    def initialize(build_id)
      @build_id = build_id
    end

    def shutdown
      node = Node.find_by! build_id: @build_id
      node.update_column :status, :aborting

      return if shutdown_using_api node.uri, node.pid
      kill_process node.pid if running? node.pid
      force_kill_process node.pid if running? node.pid
    end

    private

    def shutdown_using_api(uri, pid)
      return false if uri.nil? || uri.empty?
      NodeStarter.logger.info "Shutting down node using URI #{uri}."
      node_api = NodeApi.new uri
      result = node_api.stop
      fail "Node refused stop request with status #{result}." unless result == Net::HTTPSuccess
      NodeStarter.logger.info "Waiting for node with PID #{pid} to finish."
      Timeout.timeout(NodeStarter.config.shutdown_node_timeout_in_minutes) do
        Process.wait pid
      end
      NodeStarter.logger.info "Node with PID #{pid} finished."
      true
    rescue TimeoutError
      NodeStarter.logger.warn "Node shutdown request timed out. Address: #{uri}"
      false
    rescue => e
      NodeStarter.logger.error e
      false
    end

    def kill_process(pid)
      NodeStarter.logger.debug("Killing process #{pid} of node with build_id #{@build_id}")
      5.times.with_index do |i|
        unless running? pid
          NodeStarter.logger.debug("Node #{@build_id} terminated.")
          break
        end
        NodeStarter.logger.debug("Node #{@build_id} still alive after #{i + 1} attempts")
        Process.kill('INT', pid)
        sleep 300
      end
    end

    def force_kill_process(pid)
      NodeStarter.logger.info("Force killing node #{@build_id}")
      Process.kill('KILL', pid)
    end

    def running?(pid)
      !Sys::ProcTable.ps(pid).nil?
    end
  end
end
