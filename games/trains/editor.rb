require 'map'

class Editor

  attr_reader :map

  def initialize(w,h, net)
    @net = net
    @posx   = 5
    @posy   = 100
    @width  = 400
    @height = 400
    @map    = Map.new
    @casew  = 20
    set_size(w,h)
  end
  
  def set_size(w,h)
    @screenw, @screenh = w, h
  end
  
  def draw
    GL::BlendFunc(GL::SRC_ALPHA,GL::ONE_MINUS_SRC_ALPHA) # GL::Enable(GL::BLEND) for this to work
    
    GL::Color(0.1,0.1,0.1,0.5)
    GL::Rect(@posx, @screenh-@posy, @posx+@width,  @screenh-(@posy+@height))
    
    GL::LineWidth(1)
    GL::Color(1,1,1,0.8)
    GL::Begin(GL::LINE_LOOP)
      GL::Vertex2f(@posx,@screenh-@posy)
      GL::Vertex2f(@posx,@screenh-(@posy+@height))
      GL::Vertex2f(@posx+@width,@screenh-(@posy+@height))
      GL::Vertex2f(@posx+@width,@screenh-@posy)
    GL::End()
    
    @map.each { |x,y,c|
      #puts "#{x} #{y} #{c}"
      GL::Color(0.1,0.6,0.1,0.8)
      GL::Rect(@posx+(x+@casew/2)*@casew+1, @screenh-((-y+@casew/2)*@casew)-@posy-1, @posx+(x+@casew/2+1)*@casew-1,  @screenh-((-y+@casew/2+1)*@casew)-@posy+1)
      }
    draw_peers
    
  end
  
  def draw_peers
    @net.each_peer { |p|
      next if not p.active
      GL::Color(1, 0, 0, 1)
      GL::PointSize(6)
      GL::Begin(GL::POINTS)
        x, y = get_coords(p.pos.x, p.pos.y)
        GL::Vertex(x, y, 0)
      GL::End()
      #print p.pos.x, " ", p.pos.y, "\n"
      GL::Color(0.8, 0.3, 0.3, 1)
      text  = "#{p.name} (#{(Time.now-p.last_packet).to_i})"
      text_out(x+4, y, GLUT_BITMAP_HELVETICA_10, text)
      }
  end
  
  def get_coords(x,y)
    [@posx+@width/2+x*@casew, @screenh-(-(y-1)*@casew+@posy+@height/2)]
  end
  
  def click(x,y,state)
    return false if state==1 or not inside(x,y)
    casex, casey = (x-@posx)/@casew-@casew/2, -((y-@posy)/@casew-@casew/2)
    #lines = @map.get_all_possible_lines(casex,casey)
    
    if(@map.get_case(casex, casey) == {})
      make_links(casex,casey, true)
      make_links(casex+1,casey) 
      make_links(casex-1,casey)
      make_links(casex,casey+1)
      make_links(casex,casey-1)
    else
      @map.remove_case(casex, casey)
      make_links(casex+1,casey) 
      make_links(casex-1,casey)
      make_links(casex,casey+1)
      make_links(casex,casey-1)
    end
    return true
  end

  def make_links(casex,casey, force=false)
    return if (not force) and @map.get_case(casex, casey) == {}
    conn = connections(casex,casey)
    lines = link_connections(conn)
    @map.set_rails(casex, casey, lines)
  end
  
  def link_connections(conn)
    s = conn.size
    return [[1,5]] if s == 0
    return [[conn[0], @map.get_opp(conn[0])]] if s == 1
    rv = []
    conn.each_with_index { |c1,i1|
      conn.each_with_index { |c2,i2|
        rv << [c1,c2] if i2 != i1 and not rv.include?([c2,c1])
        }
      }
    rv
  end
  
  def connections(casex,casey)
    conn = []
    conn << 1 if @map.get_case(casex,   casey+1) != {}
    conn << 5 if @map.get_case(casex,   casey-1) != {}
    conn << 3 if @map.get_case(casex+1, casey)   != {}
    conn << 7 if @map.get_case(casex-1, casey)   != {}
    conn
  end
  
  def inside(x,y)
    return true if x > @posx and x < @posx+@width and y > @posy and y < @posy+@height
    return false
  end

end

