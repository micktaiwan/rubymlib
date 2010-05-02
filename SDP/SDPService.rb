# Juste un test pour l'instant

# require 'soap/wsdlDriver'
# wsdl = 'http://services.xmethods.net/soap/urn:xmethods-delayed-quotes.wsdl'
# driver = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
# puts "Stock price: %.2f" % driver.getQuote('TR')

SERVER = "sqli.ideoproject.com"
URL = "/sdp/sdp_tlk_interface.php"
HTTP = "http://#{SERVER}#{URL}"
CODEPROJ = "TO2089"

#require 'soap/rpc/driver'
#stub = SOAP::RPC::Driver.new(URL, "http://markwatson.com/Demo")
#stub.add_method('getChargeProjetByFilterDate', 'a_number')


#require 'socket'
require 'net/http'
require 'uri'
#require 'CGI'

class SDPService

  def initialize
  end
  
  def connect
    #@s = TCPSocket.new(SERVER,80)
  end  

  def gets
    return nil if !@s
    readfds, writefds, exceptfds = select([@s], nil, nil, 1)
    return @s.gets if readfds
    return nil
  end

  def send(msg)
    throw 'not connected' if !@s
    @s.puts msg
  end

  def get_charge
    str  = '<SOAP-ENV:Envelope SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:si="http://soapinterop.org/xsd" >'
    str += '<SOAP-ENV:Body>'
    str += ' <ns8992:getRAFCollabInProject xmlns:ns8992="http://tempuri.org">'
    str += '    <soapVal xsi:type=""xsd:string"">#{CODEPROJ}</soapVal>'
    str += '  </ns8992:getRAFCollabInProject>'
    str += '</SOAP-ENV:Body>'
    str += '</SOAP-ENV:Envelope>'
    #send str
    
    
    url = URI.parse(HTTP)
    req = Net::HTTP::Post.new(url.path)
    #req.basic_auth 'jack', 'pass'
    #req.set_form_data({'xml'=>str}, ';')
    req.body = str #CGI.escape(str) # urlencode
    req.content_type = 'application/x-www-form-urlencoded'

    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      puts res.body
    else
      puts res.body
    end
    
    return
    
    send "GET #{URL} HTTP1.0\n\n"
    begin
      msg = gets
    end while msg == nil  
    begin
      m = gets
      msg += m if m != nil
    end while m != nil  
    puts msg
  end

end

s = SDPService.new
s.connect
s.get_charge

