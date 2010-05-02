#!/usr/bin/env ruby

# another way to do it

class Journal

  def initialize
    @file = File.open('./test.txt')
    @lines = @file.readlines
    @current_date = "No date"
    parse
  end
  
  
  def parse_line(line)
    if line =~ /^\d\d:\d\d .*/    
      
    end
  end
  
  def parse
    @lines.each { |line|
      parse_line(line)
      }
  end

end


Journal.new

