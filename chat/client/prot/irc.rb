require "socket"
require 'prot/protocol'

# Don't allow use of "tainted" data by potentially dangerous operations
$SAFE=1

class IRC < Protocol

    def initialize
      @server = 'irc.efnet.fr'
      @port = 6667
      @nick = 'Alt-255'
      @channel = '#micktest'
    end
    
    def send(s)
      # Send a message to the irc server and print it to the screen
      $stdout.puts "--> #{s}"
      @irc.send "#{s}\n", 0 
    end
    
    def connect()
      # Connect to the IRC server
      @irc = TCPSocket.open(@server, @port)
      send "USER blah blah blah :blah blah"
      send "NICK #{@nick}"
      send "JOIN #{@channel}"
    end
    
    def disconnect
      @irc.close if @irc
      @irc = nil
    end
            
    def gets
      return nil if !@irc
      ready = select([@irc], nil, nil, 0.01)
      return nil if !ready
      return nil if @irc.eof
      s = @irc.gets
      handle_server_input(s)
    end
    
private

    def handle_server_input(s)
      txt = nil
      case s.strip
          when /^PING :(.+)$/i
              $stdout.puts "[ Server ping ]"
               send "PONG :#{$1}"
          when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
              $stdout.puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
              send "NOTICE #{$1} :\001PING #{$4}\001"
          when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
              $stdout.puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
              send "NOTICE #{$1} :\001VERSION RubyChat Alpha\001"
          when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:EVAL (.+)$/i
              $stdout.puts "[ EVAL #{$5} from #{$1}!#{$2}@#{$3} ]"
              send "PRIVMSG #{(($4==@nick)?$1:$4)} :#{evaluate($5)}"
          when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+)\s:(.+)$/i
              #:micktw!~mick@AToulouse-256-1-145-157.w90-45.abo.wanadoo.fr PRIVMSG #micktest :yo
              txt = "(#{$4}) #{$1}>#{$5}\n"
          else
              $stdout.puts s
      end
      return txt
    end

   
    def evaluate(s)
      # Make sure we have a valid expression (for security reasons), and
      # evaluate it if we do, otherwise return an error message
      if s =~ /^[-+*\/\d\s\eE.()]*$/ then
        begin
            s.untaint
            return eval(s).to_s
        rescue Exception => detail
            puts detail.message()
        end
      end
      return "Error"
    end

end

# The main program
# If we get an exception, then print it out and keep going (we do NOT want
# to disconnect unexpectedly!)

#irc = IRC.new('irc.efnet.fr', 6667, 'Alt-255', '#micktest')
#irc.connect()
#begin
#    irc.main_loop()
#rescue Interrupt
#rescue Exception => detail
#    puts detail.message()
#    print detail.backtrace.join("\n")
#    retry
#end

