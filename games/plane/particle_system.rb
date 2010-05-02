require 'vector'

class Force
  attr_accessor :type, :values
  
  def initialize(p, t, v)
    @particle, @type, @values = p, t, v
    case @type
    when :motor
      if v[0].respond_to?(:current)
        @center = v[0]
      else
        @center = MVector.new(v[0][0],v[0][1],v[0][2])
      end
      @normal = MVector.new(v[1][0],v[1][1],v[1][2])
      @length = v[2]
    when :uni
      @cache = MVector.new(v[0],v[1],v[2])
    end
  end
  
  def vector
    case type
      when :uni
        @cache
      when :motor
        calculate_motor_force
      else
        raise "ooops, type uknown: #{type}"
    end
  end
  
  def calculate_motor_force
    # (pos - center) x normale
    if @center.respond_to?(:current)
      c = @center.current
    else
      c = @center
    end
    ((@particle.current - c).cross(@normal)).normalize * @length
  end
  
end


class Particle

  attr_accessor :current, :old, :acc # 3D vectors
  attr_accessor :forces
  attr_reader :invmass
  
  def initialize(x,y,z)
    c = MVector.new(x.to_f,y.to_f,z.to_f)
    @current, @old = c, c
    @acc = MVector.new(0,0,0)
    @invmass = 1
    @forces = []
  end
  
  def set_mass(m)
    @invmass = 1/m.to_f
  end
  
  def add_force(type, values)
    @forces << Force.new(self, type, values)
  end

end


class Constraint

  attr_accessor :type,      # :fixed, :string, :boundary
                :particles, # particle, or [p1, p2] (for string)
                :value      # can be [x,y,z] (for fixed) or a [particle, distance] (for string) or a [coord, sup or inf, value] (for a boundary)
  
  def initialize(t,p,v)
    @type, @particles, @value = t, p, v
  end
  
  def boundary_component
    @value[0]
  end

  def boundary_comparator
    @value[1]
  end
  
  def boundary_value
    @value[2]
  end
  
end


# A ParticleSystem object is just a set of particle with constraints
class PSObject

  attr_accessor :particles, :constraints

  def initialize
    @particles = []
    @constraints = []
  end
  
  def <<(p)
    @particles << p
    p
  end
  
  def size
    @particles.size
  end
  
  def[](i)
    @particles[i]
  end
  
  def add_constraint(type,particles,values=nil)
    if values == nil
      if type == :string
        d = particles[0].current - particles[1].current        
        values = Math.sqrt(d.dot(d))
      elsif type == :fixed
        values = particles.current.to_a
      end
    end
    if particles == :all
      @particles.each_with_index { |p,i|
        @constraints << Constraint.new(type, i, values)
        }
    else
      @constraints << Constraint.new(type, particles, values)
    end
  end
  alias :c :add_constraint
  
  def add_force(type, particles, values=nil)
     if particles == :all
      @particles.each { |p|
        p.add_force(type, values)
        }
    else
      particles.add_force(type, values)
    end
  end
  alias :f :add_force
  
  def finalize
    sort_constraints
    self
  end
  
private
  def sort_constraints
    @constraints = @constraints.sort_by {|c|
      case c.type
      when :string;   1
      when :boundary; 2
      when :fixed;    3
      end
      } 
  end
  
end

class ParticleSystem

  attr_accessor :time_step, :particles, :constraints

  def initialize(set_of_objects=[])
    @objects = set_of_objects
    @time_step = 0 # shall absolutely be calculated and set before the sim start
    @gravity = MVector.new(0,0,-9.81)
    @nb_iter = 3
    @particles = []
    @constraints = []    
  end
  
  def clear_objects
    @objects.clear
    @particles.clear
    @constraints.clear
  end
  
  def <<(o)
    @objects << o.finalize
    o.particles.each   { |p| @particles   << p }
    o.constraints.each { |p| @constraints << p }
  end
  
  def next_step
    accumulate_forces
    verlet
    satisfy_constraints
  end


private
  
  # Verlet integration step
  def verlet
    @particles.each do |p|
      temp  = p.current
      p.current += p.current-p.old+p.acc*@time_step*@time_step
      p.old = temp
    end
  end
  
  # accumulate forces for each particle
  def accumulate_forces
    @particles.each do |p|
      p.acc = MVector.new(0,0,0)
      p.forces.each do |f|
        case f.type
        when :gravity
          p.acc += @gravity
        else
          p.acc += f.vector
        end
      end
    end
  end
  
  # Here constraints are satisfied
  def satisfy_constraints
    @nb_iter.times do
      @constraints.each do |c| # sorted by strings, boundaries, fixed
        case c.type
        when :string
          p1 = c.particles[0]
          p2 = c.particles[1]
          restlength = c.value
          x1 = p1.current
          x2 = p2.current
          delta = x2-x1
          deltalength = Math.sqrt(delta.dot(delta))
          diff = (deltalength-restlength)/(deltalength*(p1.invmass+p2.invmass))
          p1.current += delta*(diff*p1.invmass);
          p2.current -= delta*(diff*p2.invmass);
        when :boundary
          p = c.particles
          # read: p.current.z = 0 if not p.current.z > 0
          p.current.component_set(c.boundary_component,c.boundary_value) if not p.current.component_value(c.boundary_component).send(c.boundary_comparator, c.boundary_value)
        when :fixed
          p = c.particles
          p.current.x = c.value[0]
          p.current.y = c.value[1]
          p.current.z = c.value[2]
        end # case
      end # constraints
    end # times
  end # function
  
end
