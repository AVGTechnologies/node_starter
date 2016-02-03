require 'erb'

module NodeStarter
  # class used for preparing uss node config
  class NodeConfigStore
    def initialize(values = {})
      values.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def write_to(path)
      template_path = File.join(
        NodeStarter.root, NodeStarter.config.config_template_path)

      template = File.read(template_path)

      File.open("#{path}/config.xml", 'w+') do |f|
        f.puts ERB.new(template).result(binding)
      end
    end

    def self.write_complete_file(path, data)
      File.open("#{path}/config.xml", 'w+') { |f| f.puts data }
    end
  end
end
