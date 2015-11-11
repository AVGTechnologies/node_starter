module NodeStarter
  # class copying binary of uss node to specified path
  class PrepareBinaries
    class << self
      def write_to(path)
        FileUtils.cp_r("#{NodeStarter.config.node_binaries_path}/.", path)
      end
    end
  end
end
