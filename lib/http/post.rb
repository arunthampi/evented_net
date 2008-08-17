module EventedNet
  module HTTP
    module Post
      def post(uri, opts = {})
        unless uri.is_a?(URI)
          raise ArgumentError, "Argument passed must be a URI"
        end
        
      end
    end
  end
end