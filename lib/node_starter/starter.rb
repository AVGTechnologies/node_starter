require 'node_starter/node_config_store'
require 'node_starter/enqueue_data_store'
require 'node_starter/prepare_binaries'

module NodeStarter
  # class starting uss node process
  class Starter
    attr_reader :build_id, :dir, :pid

    def initialize(build_id, config_values, enqueue_data)
      @build_id = build_id
      config_values[:id] = build_id

      config_values[:base_address] ||= NodeStarter.config.uss_node[:base_address] + build_id
      @config_values = NodeStarter.config.uss_node.merge(config_values)
      @enqueue_data = enqueue_data
    end

    def spawn_process
      @dir = Dir.mktmpdir("running_uss_node_#{build_id}")

      NodeStarter::NodeConfigStore.new(@config_values).write_to(dir)
      NodeStarter::EnqueueDataStore.write_to(dir, @enqueue_data)
      NodeStarter::PrepareBinaries.write_to(dir)

      @t = Thread.new do
        start
      end

      @t.value
    end

    def wait_for_process_to_finish
      @t.join
    end

    def process_result
      @t.value unless @t.alive?
    end

    def cancel_process
      Thread.kill(@t)
    end

    private

    def start
      node_executable_path = File.join(dir, NodeStarter.config.node_binary_name)

      command = "#{node_executable_path} --start -e #{dir}/enqueueData.bin -c #{dir}/config.xml"
      @pid = Process.spawn({}, command)

      NodeStarter.logger.info("Node #{@config_values['id']} spawned in #{dir} with pid #{pid}")

      wait_thr = Process.detach(pid)
      @exit_code = wait_thr.join

      NodeStarter.logger.info("Node #{@config_values['id']} finished with exit code: #{@exit_code}")
      @exit_code
    end
  end
end
