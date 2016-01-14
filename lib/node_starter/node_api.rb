module NodeStarter
  # encapsulates communication with node api
  class NodeApi
    def initialize(base_uri)
      @base_uri = URI(base_uri)
      @version_prefix = 'v2'
    end

    def stop(stopped_by)
      uri = URI.join @base_uri, "#{@version_prefix}/", 'shutdown'
      req = Net::HTTP::Post.new(uri, "Content-Type": 'application/json')
      req.body = { stopped_by: stopped_by }.to_json

      Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request req
      end
    end
  end
end
