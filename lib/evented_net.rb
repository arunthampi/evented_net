$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'eventmachine'
require 'net/http'
require 'uri'

require 'http/get'
require 'http/post'
require 'http'