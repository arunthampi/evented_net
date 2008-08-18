module EventedNet
  module HTTP
    module Post
      def post(uri, opts = {})
        unless uri.is_a?(URI) && (opts[:callback].is_a?(Proc) || opts[:callback].is_a?(Method)) && opts[:callback].arity == 2
          raise ArgumentError, "uri must be a URI and opts[:callback] must be a Proc (or Method) which takes 2 args"
        end
        EM.reactor_running? ? evented_post(uri, opts) : evented_post(uri, opts)
      end
      
      
    end
  end
end