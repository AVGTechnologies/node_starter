module NodeStarter
  # class copying binary of uss node to specified path
  class PrepareBinaries
    class << self
      def write_to(path)
        fail 'Configured node_binaries_path is not a directory.' unless
          File.directory? NodeStarter.config.node_binaries_path

        FileUtils.cp_r("#{NodeStarter.config.node_binaries_path}/.", path)
      end
    end
  end
end
