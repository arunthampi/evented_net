module EventedNet
  module HTTP
    module Get
      def get(uri, opts = {})
        unless uri.is_a?(URI) && opts[:callback].is_a?(Proc) && opts[:callback].arity == 2
          raise ArgumentError, "uri must be a URI and opts[:callback] must be a proc which takes 2 args"
        end
        EM.reactor_running? ? evented_get(uri, opts) : synchronous_get(uri, opts)
      end
      
      private
        def synchronous_get(uri, opts = {})
          resp = Net::HTTP.get_response(uri)
          opts[:callback].call(resp.code, resp.body)
        end
        
        def evented_get(uri, opts = {})
          http = EM::Protocols::HttpClient.request(
            :host => uri.host, :port => uri.port,
            :request => uri.path, :query => uri.query
          )
          # Make the call back of evented_get, call the user-generated
          # callback
          http.callback do |response|
            opts[:callback].call(response.status, response.content)
          end
        end
    end
  end
end