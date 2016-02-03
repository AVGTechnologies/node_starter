$LOAD_PATH << 'lib'
require 'bundler/setup'
require 'node_starter'
require 'node_starter/queue_subscribe'

NodeStarter.setup

NodeStarter::QueueSubscribe.new.start_listening
