require 'vector'
require 'opengl_utils'

class Pos

  attr_accessor :x, :y, :casex, :casey, :delta, :from, :to
  
  def initialize(x,y,delta)
    @casex, @casey, @delta = x, y, delta
    @from = 5
    @to   = 1
    @x, @y = 0, 0
  end
    
end

class Wagon

  attr_accessor :pos, :delta

  def initialize(train, delta=0,x=0,y=0)
    @train = train
    @pos    = Pos.new(x,y,delta)
    @pos.x, @pos.y, @pos.casex, @pos.casey, @pos.delta, @pos.from, @pos.to = @train.map.get_pos(@pos.casex, @pos.casey, @pos.delta, @pos.from, @pos.to)
  end

  def draw
    v = get_pos_vector
    GL::Color(1, 1, 0, 1)
    GL::PointSize(8)
    GL::Begin(GL::POINTS)
      GL::Vertex(v.x, v.y, 0.01)
    GL::End()
    GL::Color(1, 0, 0, 1)
    #@train.text_out(v.x+0.6,v.y, GLUT_BITMAP_HELVETICA_12, "#{@pos.casex}, #{@pos.casey}, #{@pos.delta}")
  end
  
  def get_pos_vector
    @pos.x, @pos.y, @pos.casex, @pos.casey, @pos.delta, @pos.from, @pos.to = @train.map.get_pos(@pos.casex, @pos.casey, @pos.delta, @pos.from, @pos.to)
    MVector.new(@pos.x, @pos.y, 1.5)
  end
   
end

class Train

  attr_accessor :time_step
  attr_reader   :map, :speed

  def initialize(map)
    @map        = map
    @acc        = 0
    @speed      = 0
    @speed_t    = 0 # target
    @time_step  = 0
    @wagons     = []
    @acc_fact   = 4.0
    @max_acc, @min_acc = 1/(@acc_fact), -1/(@acc_fact*2)
    @stopping = false
    @cur_dir = MVector.new(0,1,0)
    nb = 1
    nb.times { |i|
      @wagons << Wagon.new(self, nb /10.0 - i/10.0)
      }
  end
  
  def draw
    @wagons.each { |w| w.draw }
  end
  
  def draw_controls
    GL::LineWidth(1)
    
    # speed
    GL::Color(0.0,1.0,0.0,1.0)
    text_out(145,80,GLUT_BITMAP_HELVETICA_12, "#{(@speed*100).to_i}")
    text_out(40,130,GLUT_BITMAP_HELVETICA_12, "(#{(@speed_t*200).to_i})")
    draw_analog([150,100],@speed, 1)
    
    # acceleration
    GL::Color(0.0,1.0,0.0,1.0)
    text_out(10,110,GLUT_BITMAP_HELVETICA_12, "#{(@acc*400).to_i}")
    value = @acc >= 0 ? @acc : 0
    GL::Color(0,0.6,0, 1.0)
    draw_control(0, value, @max_acc)

    
    # breaks
    value = @acc < 0 ? -@acc : 0
    GL::Color(0.6,0,0, 1.0)
    draw_control(1, value, -@min_acc)
  end

  def draw_control(place, value, max)
    GL.Begin(GL::LINE_LOOP)
      GL.Vertex2f(10+place*25, 2)
      GL.Vertex2f(30+place*25, 2)
      GL.Vertex2f(30+place*25, 82)
      GL.Vertex2f(10+place*25, 82)
    GL.End()
    GL.Begin(GL::QUADS)
      GL.Vertex2f(10+place*25, 2+(value/max.to_f)*80)
      GL.Vertex2f(30+place*25, 2+(value/max.to_f)*80)
      GL.Vertex2f(30+place*25, 2)
      GL.Vertex2f(10+place*25, 2)
    GL.End()
  end
  
  def accelerate(s)
    @speed_t += s/20.0
    @stopping = false 
  end
  
  def stop
    @stopping = true
    @speed_t = 0
  end
  
  def turn(d)
    w = @wagons[0]
    #case w.pos.casex
    @map.switch_next(w.pos.casex,  w.pos.casey, w.pos.from)
  end
  
  def next_step
    if @stopping
      draw_stopping
      thres = 0.001
      @acc = -@speed
      if @speed < thres and @speed > -thres
        @acc = 0
        @speed = 0
        @stopping = false
      end
    else
      @acc    = (@speed_t)/2.0
    end
    normalize_acc
    @speed += @acc  * @time_step
    @speed *= (1-@time_step/4)
    @wagons.each { |w| 
      w.pos.delta += @speed * @time_step + (@acc * @time_step * @time_step)/2.0
      #w.add_speed(@speed)
      }
  end
  
  def draw_stopping
    enable_2D
    GL::Color(1.0,0.0,0.0,1.0)
    text_out(10,100,GLUT_BITMAP_HELVETICA_18, "STOP")
    disable_2D
  end
  
  def normalize_acc
    @acc = @max_acc if @acc > @max_acc
    @acc = @min_acc if @acc < @min_acc
  end
  
  def get_pos_vector
    @wagons[0].get_pos_vector
  end
  
  def pos
    @wagons[0].pos
  end
  
  def get_dir_vector
    if @speed >= 0; w = @wagons[0]
    else;           w = @wagons[-1]
    end

    p = w.get_pos_vector
    #nc = @map.next_case(w.pos.casex, w.pos.casey, w.pos.from)
    #from = @map.get_opp(w.pos.to)
    #to   = @map.get_destination(from))
    
    if(speed >= 0)
      cam_pos = @map.get_dir_vector(w.pos.casex, w.pos.casey, w.pos.from)
    else
      cam_pos = @map.get_dir_vector(w.pos.casex, w.pos.casey, w.pos.to)
    end
    diff = cam_pos - @cur_dir
    @cur_dir += diff * time_step*0.2
  end  
   
end
