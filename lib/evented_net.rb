$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'eventmachine'
require 'net/http'
require 'uri'

# Native Extensions stolen from the 'rev' project:
# http://rev.rubyforge.org/svn/
require 'http11_client'
require 'rev_buffer'
# HTTP Classes
require 'http/connection'
require 'http/get'
require 'http/post'
# Main HTTP Module
require 'http'