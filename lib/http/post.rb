module EventedNet
  module HTTP
    module Post
      def post(uri, opts = {})
        unless uri.is_a?(URI) && (opts[:callback].is_a?(Proc) || opts[:callback].is_a?(Method)) && opts[:callback].arity == 2
          raise ArgumentError, "uri must be a URI and opts[:callback] must be a Proc (or Method) which takes 2 args"
        end
        EM.reactor_running? ? evented_post(uri, opts) : synchronous_post(uri, opts)
      end
      
      
      def synchronous_post(uri, opts)
        post_params = opts[:params] || {}
        r = Net::HTTP.post_form(uri, post_params)
        opts[:callback].call(r.code, r.body)
      end
        
      def evented_post(uri, opts)
        post_params = opts[:params] || {}
        post_params = post_params.collect{ |k,v| "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}"}.join('&')
          
        http = EventedNet::HTTP::Connection.request(
          :host => uri.host, :port => uri.port,
          :request => uri.path, :content => post_params,
          :head =>
            {
              'Content-type' => opts[:content_type] || 'application/x-www-form-urlencoded'
            },
          :method => 'POST'
        )
        # Assign the user generated callback, as the callback for 
        # EM::Protocols::HttpClient
        http.callback { |r| puts "#{r.inspect}"; opts[:callback].call(r[:status], r[:content]) }
      end
      
      def urlencode(str)
        str.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0]) }
      end
    end
  end
end