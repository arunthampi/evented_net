require "date"
require "fileutils"
require "rubygems"
require "rake/gempackagetask"

evented_net_gemspec = Gem::Specification.new do |s|
  s.name             = "evented_net"
  s.version          = File.read('VERSION').chomp
  s.platform         = Gem::Platform::RUBY
  s.has_rdoc         = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.summary          = "Evented HTTP Library. Wraps Normal HTTP GET/POST calls to use evented calls if EventMachine is running, and synchronous calls if otherwise"
  s.description      = s.summary
  s.authors          = ["Arun Thampi"]
  s.email            = "arun.thampi@gmail.com"
  s.homepage         = "http://github.com/arunthampi/evented_net"
  s.require_path     = "lib"
  s.autorequire      = "evented_net"
  s.extensions      << "ext/rev/extconf.rb"
  s.extensions      << "ext/http11_client/extconf.rb"  
  
  s.files            = %w(README.rdoc Rakefile) + Dir.glob("{lib}/**/*") + Dir.glob("{ext}/**/*")
  
  s.add_dependency "eventmachine", ">= 0.12.0"
end

Rake::GemPackageTask.new(evented_net_gemspec) do |pkg|
  pkg.gem_spec = evented_net_gemspec
end

namespace :gem do
  namespace :spec do
    desc "Update evented_net.gemspec"
    task :generate do
      File.open("evented_net.gemspec", "w") do |f|
        f.puts(evented_net_gemspec.to_ruby)
      end
    end
  end
end

task :install => :package do
  sh %{sudo gem install pkg/evented_net-#{File.read('VERSION').chomp}}
end

desc "Remove all generated artifacts"
task :clean => :clobber_package