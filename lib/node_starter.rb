require 'logger'
require 'node_starter/config'
require 'node_starter/database'

require 'sidekiq'
require 'node_starter/workers/starter'


# Namespace that handles git operations for NodeStarter
module NodeStarter
  class << self
    # rubocop:disable TrivialAccessors
    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def logger=(l)
      @logger = l
    end
    # rubocop:enable TrivialAccessors
    def config
      @config ||= NodeStarter::Config.new
    end

    def root
      File.expand_path('../..', __FILE__)
    end

    def env
      system_env || 'development'
    end

    def setup
      logger.level = config.log_level || Logger::WARN

      Database.connect

      Sidekiq.logger = NodeStarter.logger

      Sidekiq.configure_server do |config|
        config.redis = NodeStarter.config.redis
      end

      Sidekiq.configure_client do |config|
        config.redis = NodeStarter.config.redis
      end
    end

    private

    def system_env
      ENV['ENV'] || ENV['RAILS_ENV']
    end
  end
end

require 'node_starter/models'
