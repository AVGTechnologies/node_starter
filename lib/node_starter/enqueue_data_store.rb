module NodeStarter
  # class preparing enqueue date for uss node
  class EnqueueDataStore
    class << self
      def write_to(path, data)
        File.open("#{path}/enqueueData.bin", 'w+') { |f| f.puts data }
      end
    end
  end
end
