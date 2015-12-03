require 'active_record'

module NodeStarter
  # main database configuration and initialization
  module Database
    class << self
      def config
        YAML.load(File.read(File.join(NodeStarter.root, 'config', 'database.yml')))
      end

      def connect
        ActiveRecord::Base.logger = NodeStarter.logger

        ActiveRecord::Base.configurations = Database.config
        ActiveRecord::Base.establish_connection(NodeStarter.env.to_sym)
      end
    end
  end
end
