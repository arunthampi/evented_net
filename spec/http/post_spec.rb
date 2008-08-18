require File.dirname(__FILE__) + '/../spec_helper.rb'

describe "EventedNet::HTTP.post must raise an exception if the conditions for the arguments are not met" do
  it "should raise an argument error if the first parameter is not of type 'URI'" do
    uri = "http://www.google.com"
    lambda { EventedNet::HTTP.post(uri) }.should raise_error ArgumentError
  end
  
  it "should raise an argument error if the 'callback' key of the opts hash is neither a Proc nor a Method" do
    uri = URI.parse('http://www.google.com')
    lambda { EventedNet::HTTP.post(uri) }.should raise_error ArgumentError
  end

  it "should raise an argument error if the arity of the callback proc is not 2" do
    uri = URI.parse('http://www.google.com')
    callback = Proc.new { |callback| puts "I'm a fancy proc" }
    
    lambda { EventedNet::HTTP.post(uri, :callback => callback) }.should raise_error ArgumentError
  end
end
