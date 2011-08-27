require 'vector'

class Particule

  attr_accessor :pos, :speed, :acc
  
  def initialize(x,y)
    @pos    = MVector.new(x,y,0)
    @speed  = MVector.new
    @acc    = MVector.new
  end

  def update
    @speed += @acc
    @speed *= 0.95
    @pos = @pos + @speed
  end

end

