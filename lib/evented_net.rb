$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'eventmachine'
require 'net/http'
require 'uri'

require 'thin_parser'
require 'tempfile'

require 'http/models/response'
require 'http/connection'
require 'http/get'
require 'http/post'

require 'http'