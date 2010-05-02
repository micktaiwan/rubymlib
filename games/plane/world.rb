require 'rubygems' # for some it works without to load opengl
require 'opengl'
require 'camera'
require 'console'

class World

  def draw
    raise 'override draw'
  end

  def idle
    GLUT.PostRedisplay()
  end
    
  def key(k, x, y)
    case k
      when 27 # Escape
        exit
    end
    GLUT.PostRedisplay()
  end

  def special(k, x, y)
    case k
      when GLUT::KEY_UP
        @cam.move(1.0,0,0)
      when GLUT::KEY_DOWN
        @view_rotx -= 5.0
      when GLUT::KEY_LEFT
        @view_roty += 5.0
      when GLUT::KEY_RIGHT
        @view_roty -= 5.0
    end
    GLUT.PostRedisplay()
  end

  # New window size or exposure
  def reshape(width, height)
    @screen_width  = width
    @screen_height = height
    h = height.to_f / width.to_f
    GL.Viewport(0, 0, width, height)
    GL.MatrixMode(GL::PROJECTION)
    GL.LoadIdentity()
    GL.Frustum(-1.0, 1.0, -h, h, 1.5, 60.0)
    #GLU.Perspective(@fov, h, 0.1, 60.0)
    GL.MatrixMode(GL::MODELVIEW)
    GL.LoadIdentity()
  end

  def init
    raise 'override init'
  end
  
  def enable_2D
    vPort = GL.GetIntegerv(GL_VIEWPORT)

    GL.MatrixMode(GL_PROJECTION)
    GL.PushMatrix()
    GL.LoadIdentity()

    GL.Ortho(0, vPort[2], 0, vPort[3], -1, 1)
    GL.MatrixMode(GL_MODELVIEW)
    GL.PushMatrix()
    GL.LoadIdentity()
  end
  
  def disable_2D
    GL.MatrixMode(GL_PROJECTION)
    GL.PopMatrix()   
    GL.MatrixMode(GL_MODELVIEW)
    GL.PopMatrix()	
  end

  def visible(vis)
    GLUT.IdleFunc((vis == GLUT::VISIBLE ? method(:idle).to_proc : nil))
  end

  def mouse(button, state, x, y)
    @mouse = state
    @x0, @y0 = x, y
  end
  
  def motion(x, y)
    if @mouse == GLUT::DOWN
      nx = (@x0 - x).to_f * CONFIG[:mouse][:speed_factor]
      nz = (@y0 - y).to_f * CONFIG[:mouse][:speed_factor]
      @cam.move(0, nz, nx)
    end
    @x0, @y0 = x, y
  end
  
  def v(x,y,z)
    GL::Vertex3d(x,y,z)
  end
  
  def draw_grid
    GL::Begin(GL::LINES)
      GL::Color(0.3,0.3,0.3)
      x = 40
      x.times do |i|
        v(i-x/2,-x/2,0)
        v(i-x/2,x/2,0)
        v(-x/2,i-x/2,0)
        v(x/2,i-x/2,0)
      end
    GL::End()
    draw_arrows
  end

  def draw_arrows
    GL::LineWidth(3)
    GL::Begin(GL::LINES)
    GL::Color(1, 0, 0)
    v(0,0,0)
    v(1,0,0)
    GL::Color(0, 1, 0)
    v(0,0,0)
    v(0,1,0)
    GL::Color(0, 0, 1)
    v(0,0,0)
    v(0,0,1)
    GL::End()  
    GL::LineWidth(1)
  end

  def initialize(fov = 90.0)
    @fov    = fov
    @angle  = 0.0
    @frames = 0
    @t0     = 0
    @cam    = Camera.new
    @fps = 0
    @console = Console.new

    GLUT.Init()
    init()
    GLUT.DisplayFunc(method(:draw).to_proc)
    GLUT.ReshapeFunc(method(:reshape).to_proc)
    GLUT.KeyboardFunc(method(:key).to_proc)
    GLUT.SpecialFunc(method(:special).to_proc)
    GLUT.VisibilityFunc(method(:visible).to_proc)
    GLUT.MouseFunc(method(:mouse).to_proc)
    GLUT.MotionFunc(method(:motion).to_proc)
  end

  def start
    GLUT.MainLoop()
  end

end
