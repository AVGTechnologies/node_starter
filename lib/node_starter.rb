require 'logger'
require 'node_starter/config'

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
    end

    private

    def system_env
      ENV['ENV'] || ENV['RAILS_ENV']
    end
  end
end
