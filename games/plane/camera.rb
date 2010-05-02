require 'vector'

class Camera
  
  attr_accessor :pos, :view, :rot
  
  def initialize
    @pos  = MVector.new(1,-4,2)
    @rot  = MVector.new(-80,0,260)
  end
  
  # rotx, roty: rotation along x and y
  # forward: move along the direction of the view
  def move(forward,rotx,rotz)
    
    return if not (forward!=0 or rotx!=0 or rotz!=0)
    
    if CONFIG[:log][:camera]
      puts "move: forward=#{forward} rotx=#{rotx} rotz=#{rotz}"
      puts "cam: pos=#{@pos} rot=#{@rot}" 
    end

    #@pos  = @pos+@view.normalize if forward != 0
    @rot.x -= rotx
    @rot.z -= rotz

  end
  
end
