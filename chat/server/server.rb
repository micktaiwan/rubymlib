#!/usr/bin/env ruby

require 'gserver'
require 'conf'

class ChatServer < GServer
  def initialize(*args)
    super(*args)
    
    # Keep an overall record of the client IDs allocated
    # and the lines of chat
    @@client_id = 0
    @@chat = []
  end
  
  def serve(io)
    # Increment the client ID so each client gets a unique ID
    @@client_id += 1
    my_client_id = @@client_id
    my_position = @@chat.size
    
    io.puts("Welcome to the chat, client #{@@client_id}!")
    self.log "client #{@@client_id} joined"
    # Leave a message on the chat queue to signify this client
    # has joined the chat
    @@chat << [my_client_id, ""]
    
    loop do 
      # check to see if we are receiving any data 
      if IO.select([io], nil, nil, 0.2)
        # If so, retrieve the data and process it..
        line = io.gets
        next if line.chomp == ''
        if line.chomp == 'quit'
          @@chat << [my_client_id, "exited"]
          break
        end
        self.stop if line.chomp == 'shutdown'
      
        # Add the client's text to the chat array along with the
        # client's ID
        @@chat << [my_client_id, line]      
      else
        # No data, so print any new lines from the chat stream
        @@chat[my_position..-1].each_with_index do |line, index|
          io.puts("#{line[0]} says: #{line[1]}")
          self.log "#{line[0]} says: #{line[1]}"
        end
        
        # Move the position to one past the end of the array
        my_position = @@chat.size
      end
    end
    
    self.log "client #{@@client_id} disconnected"
  end
end

####################################################################

server = ChatServer.new(PORT, HOST)
server.start
puts "Listening on #{HOST}:#{PORT}"

loop do
  break if server.stopped?
  sleep(0.1)
end

puts "Server has been terminated"

