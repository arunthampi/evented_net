require 'socket'

module EventedNet
  module HTTP
    class Connection < EventMachine::Connection
      include EventMachine::Deferrable
      
      CONTENT_LENGTH    = 'Content-Length'.freeze
      TRANSFER_ENCODING = 'Transfer-Encoding'.freeze
      CHUNKED_REGEXP    = /\bchunked\b/i.freeze

      # Response
      attr_reader :response
      
      class << self
        def request(args = {})
          args[:port] ||= 80
          # According to the docs, we will get here AFTER post_init is called.
          EventMachine.connect(args[:host], args[:port], self) do |c|
            c.instance_eval { @args = args }
          end
        end
      end

      def post_init
        @response = Response.new
      end

      def connection_completed
        @connected = true
        send_request(@args)
      end
      
      def receive_data(data)
        if @response.parse(data)
          puts "RESPONSE: #{@response.inspect}"
        end
      end  

      def unbind
        if !@connected
          set_deferred_status :failed, {:status => 0} # YECCCCH. Find a better way to signal no-connect/network error.
        else
          dispatch_response
        end
      end

      def dispatch_response
        close_connection
      end

      def send_request(args)
        args[:verb] ||= args[:method] # Support :method as an alternative to :verb.
        args[:verb] ||= :get # IS THIS A GOOD IDEA, to default to GET if nothing was specified?

        verb = args[:verb].to_s.upcase
        unless ["GET", "POST", "PUT", "DELETE", "HEAD"].include?(verb)
          set_deferred_status :failed, {:status => 0} # TODO, not signalling the error type
          return # NOTE THE EARLY RETURN, we're not sending any data.
        end

        request = args[:request] || "/"
        unless request[0,1] == "/"
          request = "/" + request
        end

        qs = args[:query_string] || ""
        if qs.length > 0 and qs[0,1] != '?'
          qs = "?" + qs
        end

        # Allow an override for the host header if it's not the connect-string.
        host = args[:host_header] || args[:host] || "_"
        # For now, ALWAYS tuck in the port string, although we may want to omit it if it's the default.
        port = args[:port]

        # POST items.
        postcontenttype = args[:contenttype] || "application/octet-stream"
        postcontent = args[:content] || ""

        # ESSENTIAL for the request's line-endings to be CRLF, not LF. Some servers misbehave otherwise.
        # TODO: We ASSUME the caller wants to send a 1.1 request. May not be a good assumption.
        req = [
          "#{verb} #{request}#{qs} HTTP/1.1",
          "Host: #{host}:#{port}",
          "User-agent: #{args[:user_agent] || 'Ruby EventMachine'}",
        ]

        if verb == "POST" || verb == "PUT"
          req << "Content-type: #{postcontenttype}"
          req << "Content-length: #{postcontent.length}"
        end

        # TODO, this cookie handler assumes it's getting a single, semicolon-delimited string.
        # Eventually we will want to deal intelligently with arrays and hashes.
        if args[:cookie]
          req << "Cookie: #{args[:cookie]}"
        end

        req << ""
        reqstring = req.map {|l| "#{l}\r\n"}.join
        send_data(reqstring)

        if verb == "POST" || verb == "PUT"
          send_data(postcontent)
        end
      end
    end
  end
end