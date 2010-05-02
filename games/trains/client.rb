###############
# test client #
###############

require 'socket'

$port = 4999
$s    = UDPSocket.open

def send( msg )
  $s.send(msg, 0, '127.0.0.1', $port)
end

msg = ['pi',"TestClient","127.0.0.1", 4999].pack("A2A10A16i")
send(msg)

# map
send(['m3',1].pack('A2i'))
send(['m4',0, 1, 1, 1, 3,7].pack('A2iiisss'))

# end 
send(['en'].pack("A2"))

