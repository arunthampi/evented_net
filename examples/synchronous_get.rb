# Most of this code is stolen from Igvita's excellent blog post on EventMachine:
# http://www.igvita.com/2008/05/27/ruby-eventmachine-the-speed-demon/

require File.dirname(__FILE__) + "/../lib/evented_net"

callback = Proc.new {|a,b| puts "Code: #{a} Body: #{b}"}
EventedNet::HTTP.get(URI.parse('http://www.maxmind.com/app/locate_ip'), :callback => callback)
