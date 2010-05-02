require 'set'

class Tokenizer

  def initialize
    @valid_chars = Set.new
    @stop = Set.new
    @simple = Set.new

    ('a'..'z').each { |c| @valid_chars.add(c) }
    ('A'..'Z').each { |c| @valid_chars.add(c) }
    ['-'].each { |c| @simple.add(c) }
    ['\''].each { |c| @valid_chars.add(c) }
  end
  
  
  def parse(text)

    rv = []
    i = 0
    s = text.size

    while i < s do
      j = i
      # break if j > i and @stop.include?(text[j].chr) # stop if we found a word delimiter other than a space

      while j < s and @valid_chars.include?( text[j].chr ) do 
        # while it is a valid char append it to the current word
        j += 1
      end
      # save:
      rv << text[i..j-1] if j > i
      i = j+1
    end

    #puts 'results'
    #puts rv.join(',')

    rv

  end
  
end
