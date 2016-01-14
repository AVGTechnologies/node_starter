require 'node_starter/node_config_store'
require 'node_starter/enqueue_data_store'
require 'node_starter/prepare_binaries'

module NodeStarter
  # class starting uss node process
  class Starter
    attr_reader :build_id, :dir, :pid

    def initialize(build_id, config_values, enqueue_data, node_api_uri)
      @node_api_uri = node_api_uri
      @build_id = build_id
      @config_values = config_values
      @enqueue_data = enqueue_data
    end

    def start_node_process
      @dir = Dir.mktmpdir("uss_node_#{@build_id}")
      NodeStarter.logger.info "Node temporary directory: #{@dir}"

      NodeStarter::NodeConfigStore.write_complete_file(dir, @config_values)
      NodeStarter::EnqueueDataStore.write_to(dir, @enqueue_data)
      NodeStarter::PrepareBinaries.write_to(dir)

      start
    end

    private

    def start
      node = Node.create!(
        build_id: @build_id,
        path: @dir,
        status: :created,
        uri: @node_api_uri
      )
      node.save!

      NodeStarter.logger.debug("starting node: #{node}")

      dir = node.path
      node_executable_path = File.join(dir, NodeStarter.config.node_binary_name)

      command = "#{node_executable_path} --start -e #{dir}/enqueueData.bin -c #{dir}/config.xml"
      pid = nil
      IO.pipe do |_, w|
        pid = Process.spawn(command, out: w)
      end
      NodeStarter.logger.info("Node #{node.build_id} spawned in #{dir} with pid #{pid}")

      node.status = :running
      node.pid = pid
      node.save!

      Process.wait(pid)

      node.status = :finished
      node.save!

      clean_up
    end

    def clean_up
      NodeStarter.logger.info("Cleaning up node #{@build_id} spawned in #{@dir}")
      backup_logs
      FileUtils.rm_rf @dir
    end

    def backup_logs
      logs_path = File.join @dir, 'debug.log'
      target_file_name = "#{@build_id}.log"
      target_path = File.join NodeStarter.config.uss_node.logs_storage_path, target_file_name
      if File.exist? logs_path
        FileUtils.cp logs_path, target_path
      else
        NodeStarter.logger.warn "Node #{@build_id} created no log file."
      end
    end
  end
end
