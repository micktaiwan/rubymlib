# April 30, 2008
#   does not work, just a test

require 'config' # must contain the google key in CONFIG[:google][:key]
require 'soap/element'
require 'soap/rpc/driver'
require 'soap/processor'
require 'soap/streamHandler'
require 'soap/property'


BASEURL = 'http://api.google.com/search/beta2' # Googles API URI

class GoogleSearch

  def initialize
    @stream = SOAP::HTTPStreamHandler.new(SOAP::Property.new)
  end
  
  def search(q)
    xml             = "key=#{CONFIG[:google][:key]}&amp;q=#{q}&amp;maxResults=3"
    header          = SOAP::SOAPHeader.new
    body_item       = SOAP::SOAPElement.new('doGoogleSearch', xml)
    body            = SOAP::SOAPBody.new(body_item)
    envelope        = SOAP::SOAPEnvelope.new(header, body)
    request_string  = SOAP::Processor.marshal(envelope)
    request         = SOAP::StreamHandler::ConnectionData.new(request_string)

    resp_data       = @stream.send(BASEURL, request, 'doGoogleSearch')

    resp_data.receive_string 
  end

end

g = GoogleSearch.new
puts g.search('test')


