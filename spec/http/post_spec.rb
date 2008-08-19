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

describe "EventedNet::HTTP.get must make a synchronous HTTP POST request if EventMachine is not running" do
  before(:each) do
    @uri = URI.parse('http://www.cs.tut.fi/cgi-bin/run/~jkorpela/echo.cgi')
    @callback = Proc.new {|a,b| puts "#{a},#{b}"}
    @response = mock(Net::HTTPResponse)
    @response.stub!(:code).and_return(200)
    @response.stub!(:body).and_return('<body>hot</body>')
    
    EM.should_receive(:reactor_running?).and_return(false)
  end
  
  it "should call the private method synchronous_get if EventMachine is not running" do
    EventedNet::HTTP.should_receive(:synchronous_post).with(@uri, { :callback => @callback , :params => {:Comments => 'Testing Attention Please'}})
    EventedNet::HTTP.post(@uri, :callback => @callback, :params => {:Comments => 'Testing Attention Please'})
  end
  
  it "should call the standard Ruby Net::HTTP.get_response method and then call the 'callback' proc object" do
    Net::HTTP.should_receive(:post_form).with(@uri, :Comments => 'Testing Attention Please').and_return(@response)
    @callback.should_receive(:call).with(200, '<body>hot</body>')
    
    EventedNet::HTTP.post(@uri, {:callback => @callback, :params => {:Comments => 'Testing Attention Please'}})
  end
end

describe "EventedNet::HTTP.get must make an evented HTTP POST request if EventMachine is running" do
  before(:each) do
    @uri = URI.parse('http://www.cs.tut.fi/cgi-bin/run/~jkorpela/echo.cgi')
    @callback = Proc.new {|a,b| puts "#{a},#{b}"}
    
    EM.should_receive(:reactor_running?).and_return(true)
  end
  
  it "should call the method evented_post if EventMachine is running" do
    EventedNet::HTTP.should_receive(:evented_post).with(@uri, {:callback => @callback, :params => {:Comments => 'Testing Attention Please'}})
    EventedNet::HTTP.post(@uri, :callback => @callback, :params => {:Comments => 'Testing Attention Please'})
  end
  
  it "should call the standard Ruby Net::HTTP.get_response method and then call the 'callback' proc object" do
    mock_client = mock(EventedNet::HTTP::Connection)
    EventedNet::HTTP::Connection.should_receive(:request).with({:host => 'www.cs.tut.fi', :port => 80,
                                                                :request => '/cgi-bin/run/~jkorpela/echo.cgi',
                                                                :method=>"POST",
                                                                :head=>{"Content-type"=>"application/x-www-form-urlencoded"},
                                                                :content => 'Comments=Testing%20Attention%20Please'}).and_return(mock_client)
    
    mock_client.should_receive(:callback)
    
    EventedNet::HTTP.post(@uri, :callback => @callback, :params => {:Comments => 'Testing Attention Please'})
  end
end