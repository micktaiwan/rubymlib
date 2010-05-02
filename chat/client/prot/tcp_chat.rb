require 'socket'
require 'timeout'

class ChatClient

  def initialize(host, port)
    @host, @port = host, port
    @s = nil
  end
  
  def connect
    begin
      timeout(5) do
          @s = TCPSocket.new(@host, @port)
      end
    rescue
        puts "Error: #{$!}"
    end
  end
  
  def disconnect
    @s.close if @s
    @s = nil
  end

  def send_msg(msg)
    throw 'not connected' if !@s
    @s.puts msg
  end

  def gets
    return nil if !@s
    readfds, writefds, exceptfds = select([@s], nil, nil, 0.1)
    return @s.gets if readfds
    return nil
  end

end


