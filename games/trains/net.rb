require 'udp_server'
require 'vector'

class Peer

  attr_reader :name, :ip, :pos
  attr_accessor :active, :last_packet

  def initialize(name,ip,port)
    puts "New peer: #{name}, #{ip}, #{port}"
    @name, @ip, @port = name,ip,port
    @socket = UDPSocket.open
    @pos = MVector.new
    @active = false
    @last_packet = nil
  end

  def send(msg)
    #puts "sending #{msg} to #{@name} (#{@ip}:#{@port})"
    @socket.send(msg,0,@ip,@port)
  end
  
end

class Network

  def initialize(name, h, p, autostart=true)
    @name, @host, @port = name, h, p
    @udp = UDPServer.new('',@port) # host is used to send our ip to new peer
    @peers = []
    @msgs = []
    start if autostart
    eval(File.read('net_ini.rb'))
  end
  
  def add_peer(name, ip, port)
    p = Peer.new(name,ip,port)
    @peers << p
    ping_pong(p,'pi') 
  end
  
  def ping_all
    @peers.each { |p| ping_pong(p,'pi') }
  end
  
  def ping_pong(e,type)
    m = [type,@name, @host, @port].pack("A2A10A16i")
    e.send(m)
  end
  
  def start
    Thread.abort_on_exception = true
    Thread.start do
      loop do
        loop do
          m = @udp.read
          break if not m
          #puts m.inspect
          e = search_by_ip(m[4])
          e = make_peer_from_ping(m) if not e
          next if not e
          e.active = true
          e.last_packet = Time.now
          case m[0][0..1]
            when 'pi'
              puts "ping from #{e.name}"
              ping_pong(e,'po')
            when 'po'
              puts "pong from #{e.name}"
            when 'mo'
              #puts "move from #{e.name}"
              c, e.pos.x, e.pos.y = m[0].unpack("A2ii")
              e.pos.x /= 100.0
              e.pos.y /= 100.0
              #@msgs << ['mo',e]
            when 'en'
              puts "end from #{e.name}"
              e.active = false
            when 'm1'
              puts "map proposal from #{e.name}"
              e.send('m2')
            when 'm2'
              puts "map request from #{e.name}"
              @msgs << ['m2',e]
            when 'm3' # map clear
              @msgs << [m[0],e]
            when 'm4' # map rails
              @msgs << [m[0],e]
          else
            puts "'#{m[0]}' from #{m[4]}"
          end
        end
        sleep(0.2)
      end
    end
  end

  def send(msg,ip)
    e = search_by_ip(ip)
    if not e
      puts "no ip #{ip}"
      return
    end
    e.send(msg)
  end

  def broadcast(msg)
    @peers.each {|p| 
      p.send(msg) if p.active
      }    
  end
  
  def make_peer_from_ping(msg)
    # first make sure we have the peer infos in the message
    command = msg[0][0..1]
    if(command != 'pi' and command != 'po')
      #ping_pong(msg[4],'ip')
      puts "Missing a port from #{msg[4]}"
      return nil
    end
    # create a new peer from the infos
    command, name, host, port = msg[0].unpack("A2A10A16i")
    e = Peer.new(name,host,port)
    @peers << e
    e
  end
  
  def search_by_ip(ip)
    @peers.each {|e| return e if e.ip==ip}
    return nil
  end
  
  def read
    @msgs.shift
  end
  
  def each_peer
    @peers.each {|p| yield p }
  end

end
