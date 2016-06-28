require 'node_starter/config'
require 'node_starter/database'
require 'node_starter/killer'
require 'node_starter/consumer'
require 'node_starter/shutdown_consumer'
require 'node_starter/reporting_publisher'

# Namespace that handles git operations for NodeStarter
module NodeStarter
  class << self
    # rubocop:disable TrivialAccessors
    def logger
      return @logger if @logger
      setup_console_logger
      setup_file_logger
      @logger
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
      Database.connect
    end

    private

    def system_env
      ENV['ENV'] || ENV['RAILS_ENV']
    end

    def setup_console_logger
      @logger = Logger.new(STDOUT)
      logger.level = config.log_level
      @logger
    end

    def setup_file_logger
      log_directory = config.file_log_directory
      Dir.mkdir log_directory unless File.directory? log_directory
      file_log = file_logger(log_directory)
      @logger.extend(ActiveSupport::Logger.broadcast(file_log))
    end

    def file_logger(log_directory)
      log_path = File.join(log_directory, 'node_starter.log')
      file_logger = Logger.new(log_path,
                               config.file_log_shift_age,
                               config.file_log_shift_size)
      file_logger.level = config.file_log_level
      file_logger
    end
  end
end

require 'node_starter/models'
