require 'opengl'
require 'glut'

class World

  def draw
    raise 'override draw'
  end

  def idle
    t = GLUT.Get(GLUT::ELAPSED_TIME) / 1000.0
    @t0_idle = t if !defined? @t0_idle
    # 90 degrees per second
    @angle += 70.0 * (t - @t0_idle)
    @t0_idle = t
    GLUT.PostRedisplay()
  end

  # Change view angle, exit upon ESC
  def key(k, x, y)
    case k
      when ?z
        @view_rotz += 5.0
      when ?Z
        @view_rotz -= 5.0
      when 27 # Escape
        exit
    end
    GLUT.PostRedisplay()
  end

  # Change view angle
  def special(k, x, y)
    case k
      when GLUT::KEY_UP
        @view_rotx += 5.0
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
    h = height.to_f / width.to_f
    GL.Viewport(0, 0, width, height)
    GL.MatrixMode(GL::PROJECTION)
    GL.LoadIdentity()
    GL.Frustum(-1.0, 1.0, -h, h, 5.0, 60.0)
    #GLU.Perspective(@fov, h, 0.1, 1024.0)
    GL.MatrixMode(GL::MODELVIEW)
    GL.LoadIdentity()
  end

  def init
    raise 'override init'
  end

  def visible(vis)
    GLUT.IdleFunc((vis == GLUT::VISIBLE ? method(:idle).to_proc : nil))
  end

  def mouse(button, state, x, y)
    @mouse = state
    @x0, @y0 = x, y
  end
  
  def motion(x, y)
    if @mouse == GLUT::DOWN then
      @view_roty -= @x0 - x
      @view_rotx -= @y0 - y
    end
    @x0, @y0 = x, y
  end

  def initialize(fov = 90.0)
    @fov = fov
    @angle = 0.0
    @view_rotx, @view_roty, @view_rotz = 10.0, 0.0, 0.0
    @view_pos = {:x=>0.0, :y=>10.0, :z=>20.0}
    @frames = 0
    @t0 = 0

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

if $0 == __FILE__
  World.new.start
end
