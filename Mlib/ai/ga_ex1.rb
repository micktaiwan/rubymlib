# population of 5's is seeked

require 'ga'

class MyPop < Population

  def initialize
    clear
    20.times do; self << rand(10); end
  end
  
  # calculate a individual fitness
  def fitness individual
    (5 - individual).abs
  end
  
  def breed(i,j)
    (i+j)/2
  end
  
  def to_s
    self.join(', ')
  end
    
end

p = MyPop.new
10.times do
  puts "#{p.global_fitness}: #{p.to_s}"
  p.generate
end
