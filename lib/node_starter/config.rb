require 'settingslogic'

module NodeStarter
  # class representing project configuration
  class Config < Settingslogic
    def initialize(source = nil, section = nil)
      source ||=
        File.join(NodeStarter.root, 'config', 'node_starter.yml')

      self.class.namespace NodeStarter.env
      super(source, section)
    end
  end
end
