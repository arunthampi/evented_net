Gem::Specification.new do |s|
  s.name = %q{evented_net}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Arun Thampi"]
  s.autorequire = %q{evented_net}
  s.date = %q{2008-08-19}
  s.description = %q{Evented HTTP Library. Wraps Normal HTTP GET/POST calls to use evented calls if EventMachine is running, and synchronous calls if otherwise}
  s.email = %q{arun.thampi@gmail.com}
  s.extensions = ["ext/rev/extconf.rb", "ext/http11_client/extconf.rb"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "Rakefile", "lib/evented_net.rb", "lib/http", "lib/http/connection.rb", "lib/http/get.rb", "lib/http/post.rb", "lib/http.rb", "lib/http11_client.bundle", "lib/rev_buffer.bundle", "ext/http11_client", "ext/http11_client/ext_help.h", "ext/http11_client/extconf.rb", "ext/http11_client/http11_client.c", "ext/http11_client/http11_parser.c", "ext/http11_client/http11_parser.h", "ext/http11_client/http11_parser.rl", "ext/rev", "ext/rev/extconf.rb", "ext/rev/Makefile", "ext/rev/rev_buffer.bundle", "ext/rev/rev_buffer.c", "ext/rev/rev_buffer.o"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/arunthampi/evented_net}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Evented HTTP Library. Wraps Normal HTTP GET/POST calls to use evented calls if EventMachine is running, and synchronous calls if otherwise}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0.12.0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.12.0"])
  end
end
