# Most of this code is stolen from Igvita's excellent blog post on EventMachine:
# http://www.igvita.com/2008/05/27/ruby-eventmachine-the-speed-demon/

require File.dirname(__FILE__) + "/../lib/evented_net"
require 'evma_httpserver'
require 'cgi'

class Handler  < EventMachine::Connection
  include EventMachine::HttpServer

  def process_evented_http_req(code, body)
    puts "Code: #{code} Body: #{body}"
  end
 
  def process_http_request
    uri = URI.parse('http://www.cs.tut.fi/cgi-bin/run/~jkorpela/echo.cgi')
    EventedNet::HTTP.post(uri, :callback => method(:process_evented_http_req), :params => {:Comments => 'Testing Attention Please'})
  end
end

EventMachine::run {
  EventMachine.kqueue
  EventMachine::start_server("0.0.0.0", 8082, Handler)
  puts "Listening"
}