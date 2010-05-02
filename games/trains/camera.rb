require 'vector'

class Camera
  
  attr_accessor :pos, :view, :rot
  
  def initialize
    @pos  = MVector.new(0.5,-2.5,1.6)
    @rot  = MVector.new(-70,0,0)
    @follow = {:obj=>nil}
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
  
  # give a object and a method to to call to get a MVector (a point) to follow
  # opt can be nil or [:pos, distance], meaning change cam pos following p at distance
  # to do that we need to call a method that gives us a direction vector
  def set_follow(obj, obj_pos_method=nil, obj_dir_method=nil, opt=nil)
    @follow     = {:obj=>obj, :pos_m=>obj_pos_method, :dir_m=>obj_dir_method, :opt=>opt}
  end
  
  def follow
    return if not @follow[:obj]
    pos = @follow[:obj].send(@follow[:pos_m])
    
    if(opt = @follow[:opt])
      if (d = opt[:distance])
        d = 0.001 if d == 0
        dir = @follow[:obj].send(@follow[:dir_m]).normalize
        @pos = pos - (dir*d)
        if(opt[:side])
          tan = dir.cross(MVector.new(0,0,1)).normalize * opt[:side]
          @pos = @pos - tan
        end
        @pos.z = pos.z
      elsif (from = opt[:position]) # mutually exclusive with distance
        @pos = from.send(@follow[:pos_m])
      end
    end

    x = @pos.x - pos.x
    y = @pos.y - pos.y
    #z = @pos.z - pos.z
    scale = 45/Math.atan(1) 
    rotz = (scale*Math.atan2(y,x))+90
    @rot.z = -rotz
  end
  
end
