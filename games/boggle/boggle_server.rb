# File boggle_server.rb
# Copyright 2007 J. Eric Ivancich, all rights reserved.
# Licensed under the Creative Commons Attribution Non-commercial Share
# Alike license (see: http://creativecommons.org/licenses/by-nc-sa/3.0/).


require 'boggle_solver'
require 'socket'


# This module has the methods to implement a Boggle server.
module BoggleServer

  
  ServerHost = 'localhost'
  ServerPort = 0x80cc
  ServerTimeout = 60 * 10  # 10 minutes
  DictFile = 'boggle.dict'
  

  # Returns true if the server is running, false if not.
  def self.server_running?
    socket = TCPSocket.new(ServerHost, ServerPort)
    YAML.dump("hello", socket)
    socket.close_write
    response = YAML.load(socket)
    socket.close_read
    response == "hello back"
  rescue Errno::ECONNREFUSED => e
    return false
  end


  # Forks off a process to run the server.  The server loops, wating
  # for connections and processing them.  The server stops when it
  # gets a shutdown message or when the timeout expires without any
  # connections.  All incoming messages are in YAML as are the
  # responses.
  def self.spawn(dict_file = DictFile)
    solver = BoggleSolver::Solver.new(dict_file)
    
    fork do
      connection = TCPServer.new(ServerHost, ServerPort)
      
      loop do
        # if no connections before timeout, shutdown server
        break unless select([connection], nil, nil, ServerTimeout)

        socket = connection.accept
        message = YAML.load(socket)
        case message
        when 'hello'
          YAML.dump('hello back', socket)
        when 'shutdown'
          break
        when Array
          t1 = Time.now
          result = solver.solve(message)
          t2 = Time.now
          YAML.dump(result, socket)
        else
          YAML.dump('error: unknown message', socket)
        end
        socket.shutdown
      end  # loop
      
      connection.shutdown
    end  # fork
  rescue Errno::EADDRINUSE
    raise "could not start server"
  end


  # Returns immediately if server is running, or launches server and
  # verifies that it is running before returning.
  def self.server_assure
    unless BoggleServer::server_running?
      BoggleServer::spawn
      
      50.times do |count|
        break if BoggleServer::server_running?
        sleep 0.1
      end
      
      unless BoggleServer::server_running?
        raise 'could not start server'
      end
    end
  end
  

  # Requests that the server closes down.
  def self.server_shutdown
    socket = TCPSocket.new(ServerHost, ServerPort)
    YAML.dump('shutdown', socket)
    socket.shutdown
    return true
  rescue Errno::ECONNREFUSED => e
    return false
  end


  # Takes a board and sends it to the server for solving.  Returns the
  # result.
  def self.server_solve(board)
    socket = TCPSocket.new(ServerHost, ServerPort)
    YAML.dump(board, socket)
    socket.close_write
    result = YAML.load(socket)
    #socket.shutdown
    result
  end
end


# If this script is run on its own, shuts down the server if it's
# running.
if $0 == __FILE__
  BoggleServer::server_shutdown
end


