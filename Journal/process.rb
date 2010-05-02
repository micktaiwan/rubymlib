#!/usr/bin/env ruby

class Journal

  def initialize
    @file = File.open('./journal.txt')
    @lines = @file.readlines
    @current_date = "No date"
    parse
  end
  
  
  def parse_line(line)

    
  end
  
  def parse
    @lines.each { |line|
      parse_line(line)
      }
  end

end


Journal.new

