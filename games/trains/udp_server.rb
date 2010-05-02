require 'socket'

class UDPServer

  def initialize(host, port, autostart=true)
    # read UDP pickaxe docs (p. 774) for host
    @host, @port = host, port
    @s = UDPSocket.open
    @s.bind(@host, @port)
    @msgs = [] #Queue.new
    @count = 0
    start if autostart
  end
    
  def start
    #puts "Listening on #{@host}:#{@port}"
    Thread.abort_on_exception = true
    Thread.start do
      loop do
        @msgs << [@s.recvfrom(255),@count]
        @count += 1
      end
    end
  end

  def read
    m = @msgs.shift
    return nil if not m
    m << @count-1
    m.flatten
  end

end
