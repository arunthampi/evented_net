require 'socket'

module EventedNet
  module HTTP
     # A simple hash is returned for each request made by HttpClient with
     # the headers that were given by the server for that request.
     class HttpResponseHeader < Hash
       # The reason returned in the http response ("OK","File not found",etc.)
       attr_accessor :http_reason

       # The HTTP version returned.
       attr_accessor :http_version

       # The status code (as a string!)
       attr_accessor :http_status

       # HTTP response status as an integer
       def status
         Integer(http_status) rescue nil
       end

       # Length of content as an integer, or nil if chunked/unspecified
       def content_length
         Integer(self[Connection::CONTENT_LENGTH]) rescue nil
       end

       # Is the transfer encoding chunked?
       def chunked_encoding?
         /chunked/i === self[Connection::TRANSFER_ENCODING]
       end
    end

    class HttpChunkHeader < Hash
      # When parsing chunked encodings this is set
      attr_accessor :http_chunk_size

      # Size of the chunk as an integer
      def chunk_size
        return @chunk_size unless @chunk_size.nil?
        @chunk_size = @http_chunk_size ? @http_chunk_size.to_i(base=16) : 0
      end
    end

    # Methods for building HTTP requests
    module HttpEncoding
      HTTP_REQUEST_HEADER="%s %s HTTP/1.1\r\n"
      FIELD_ENCODING = "%s: %s\r\n"

      # Escapes a URI.
      def escape(s)
        s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
          '%'+$1.unpack('H2'*$1.size).join('%').upcase
        }.tr(' ', '+') 
      end

      # Unescapes a URI escaped string.
      def unescape(s)
        s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){
          [$1.delete('%')].pack('H*')
        } 
      end

      # Map all header keys to a downcased string version
      def munge_header_keys(head)
        head.inject({}) { |h, (k, v)| h[k.to_s.downcase] = v; h }
      end

      # HTTP is kind of retarded that you have to specify
      # a Host header, but if you include port 80 then further
      # redirects will tack on the :80 which is annoying.
      def encode_host
        remote_host + (remote_port.to_i != 80 ? ":#{remote_port}" : "")
      end

      def encode_request(method, path, query)
        HTTP_REQUEST_HEADER % [method.to_s.upcase, encode_query(path, query)]
      end

      def encode_query(path, query)
        return path unless query
        path + "?" + query.map { |k, v| encode_param(k, v) }.join('&')
      end

      # URL encodes a single k=v parameter.
      def encode_param(k, v)
        escape(k) + "=" + escape(v)
      end

      # Encode a field in an HTTP header
      def encode_field(k, v)
        FIELD_ENCODING % [k, v]
      end

      def encode_headers(head)
        head.inject('') do |result, (key, value)|
          # Munge keys from foo-bar-baz to Foo-Bar-Baz
          key = key.split('-').map { |k| k.capitalize }.join('-')
        result << encode_field(key, value)
        end
      end

      def encode_cookies(cookies)
        cookies.inject('') { |result, (k, v)| result << encode_field('Cookie', encode_param(k, v)) }
      end
    end
    
    class Connection < EventMachine::Connection
      include EventMachine::Deferrable
      include HttpEncoding
      
      ALLOWED_METHODS=[:put, :get, :post, :delete, :head]
      TRANSFER_ENCODING="TRANSFER_ENCODING"
      CONTENT_LENGTH="CONTENT_LENGTH"
      SET_COOKIE="SET_COOKIE"
      LOCATION="LOCATION"
      HOST="HOST"
      CRLF="\r\n"
      
      class << self
        def request(args = {})
          args[:port] ||= 80
          # According to the docs, we will get here AFTER post_init is called.
          EventMachine.connect(args[:host], args[:port], self) do |c|
            c.instance_eval { @args = args }
          end
        end
      end
      
      def remote_host
        @args[:host]
      end
      
      def remote_port
        @args[:port]
      end
      
      def post_init
        @parser = Rev::HttpClientParser.new
        @parser_nbytes = 0
        @state = :response_header
        @data = Rev::Buffer.new
        @response_header = HttpResponseHeader.new
        @chunk_header = HttpChunkHeader.new
      end
      
      def connection_completed
        @connected = true
        send_request(@args)
      end
      
      def send_request(args)
        send_request_header(args)
        send_request_body(args)
      end
      
      def send_request_header(args)
        query   = args[:query]
        head    = args[:head] ? munge_header_keys(args[:head]) : {}
        cookies = args[:cookies]
        body    = args[:body]
        path    = args[:request]
        
        path = "/#{path}" if path[0,1] != '/'
        
        # Set the Host header if it hasn't been specified already
        head['host'] ||= encode_host
        # Set the Content-Length if it hasn't been specified already and a body was given
        head['content-length'] ||= body ? body.length : 0
        # Set the User-Agent if it hasn't been specified
        head['user-agent'] ||= "EventedNet::HTTP::Connection"
        # Default to Connection: close
        head['connection'] ||= 'close'
        # Build the request
        request_header = encode_request(args[:method] || 'GET', path, query)
        request_header << encode_headers(head)
        request_header << encode_cookies(cookies) if cookies
        request_header << CRLF
        # Finally send it
        send_data(request_header)
      end
      
      def send_request_body(args)
        send_data(args[:body]) if args[:body]
      end  
      
      def receive_data(data)
        @data << data
        dispatch
      end

      # Called when response header has been received
      def on_response_header(response_header)
      end

      # Called when part of the body has been read
      def on_body_data(data)
        puts "Data: #{data}"
#        STDOUT.write data
#        STDOUT.flush
      end

      # Called when the request has completed
      def on_request_complete
        close_connection
      end

      # Called when an error occurs dispatching the request
      def on_error(reason)
        close_connection
        raise RuntimeError, reason
      end
      
      def dispatch
        while @connected and case @state
          when :response_header
            parse_response_header
          when :chunk_header
            parse_chunk_header
          when :chunk_body
            process_chunk_body
          when :chunk_footer
            process_chunk_footer
          when :response_footer
            process_response_footer
          when :body
            process_body
          when :finished, :invalid
            break
          else raise RuntimeError, "invalid state: #{@state}"
          end
        end
      end
      
      def parse_header(header)
        return false if @data.empty?

        begin
          @parser_nbytes = @parser.execute(header, @data.to_str, @parser_nbytes)
        rescue Rev::HttpClientParserError
          on_error "Invalid HTTP format, parsing fails"
          @state = :invalid
        end

        return false unless @parser.finished?

        # Clear parsed data from the buffer
        @data.read(@parser_nbytes)
        @parser.reset
        @parser_nbytes = 0

        true
      end
      
      def parse_response_header
        return false unless parse_header(@response_header)

        unless @response_header.http_status and @response_header.http_reason
          on_error "no HTTP response"
          @state = :invalid
          return false
        end

        on_response_header(@response_header)

        if @response_header.chunked_encoding?
          @state = :chunk_header
        else
          @state = :body
          @bytes_remaining = @response_header.content_length
        end

        true
      end

      def parse_chunk_header
        return false unless parse_header(@chunk_header)

        @bytes_remaining = @chunk_header.chunk_size
        @chunk_header = HttpChunkHeader.new

        @state = @bytes_remaining > 0 ? :chunk_body : :response_footer      
        true
      end

      def process_chunk_body
        if @data.size < @bytes_remaining
          @bytes_remaining -= @data.size
          on_body_data(@data.read)
          return false
        end

        on_body_data(@data.read(@bytes_remaining))
        @bytes_remaining = 0

        @state = :chunk_footer      
        true
      end

      def process_chunk_footer
        return false if @data.size < 2

        if @data.read(2) == CRLF
          @state = :chunk_header
        else
          on_error "non-CRLF chunk footer"
          @state = :invalid
        end

        true
      end

      def process_response_footer
        return false if @data.size < 2

        if @data.read(2) == CRLF
          if @data.empty?
            on_request_complete
            @state = :finished
          else
            on_error "Garbage at end of chunked response"
            @state = :invalid
          end
        else
          on_error "Non-CRLF response footer"
          @state = :invalid
        end

        false
      end

      def process_body
        if @bytes_remaining.nil?
          on_body_data(@data.read)
          return false
        end

        if @bytes_remaining.zero?
          on_request_complete
          @state = :finished
          return false
        end

        if @data.size < @bytes_remaining
          @bytes_remaining -= @data.size
          on_body_data(@data.read)
          return false
        end
        
        on_body_data(@data.read(@bytes_remaining))
        @bytes_remaining = 0
        if @data.empty?
          on_request_complete
          @state = :finished
        else
          on_error "garbage at end of body"
          @state = :invalid
        end

        false
      end
    end
  end
end