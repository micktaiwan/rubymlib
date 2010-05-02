
class Protocol

  def initialize
  end
  
  # to connect to the server
  def connect
    $stderr.puts "connect not implemented"
  end
  
  def disconnect
    $stderr.puts "disconnect not implemented"
  end
  
  # to send something to the server
  def send(s)
    $stderr.puts "send not implemented"
  end
  
  # to get something from the server
  # return nil if nothing to return
  def gets
    $stderr.puts "gets not implemented"
  end
    
end

