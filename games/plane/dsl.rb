# helper class to simplify the definition language
require 'particle_system'

class DSL

  def initialize(ps, c)
    @ps, @console = ps, c
  end

  def reload
    @ps.clear_objects
    begin
      eval(File.read('objects.rb'))
      @console.push "#{@ps.particles.size} particules reloaded"
    rescue Exception => e
      @console.push "Error in the objects.rb file:\n*** #{e.message}"
      raise
    end
  end
 
  
  def p(x,y,z,mass=1.0)
    #@console.push "particule"
    p = Particle.new(x,y,z)
    p.set_mass(mass)
    @current_object << p
    p
  end

  def c(t,i,v=nil)
    @current_object.c(t,i,v)
  end
  
  def f(t,p,v=nil)
    @current_object.f(t,p,v)
  end
  
  
  def object(name=nil)
    #@console.push "object"
    @current_object = PSObject.new
  end

  def end_object
    @ps << @current_object
  end
  
  def gravity p
    p = resolve(p)
    @current_object.f(:gravity, p)
  end
  
  def fix p
    p = resolve(p)
    @current_object.c(:fixed,p)
  end
  
  def string p1, p2=nil
    p1 = resolve(p1)
    if p2 == nil # p1 should be :last_two
      return if p1[0] == nil
      @current_object.c(:string,p1)
    else
      p2 = resolve(p2)
      @current_object.c(:string,[p1,p2])
    end
  end
  
  def motor p, center, normal_vector, power
    p = resolve(p)
    @current_object.f(:motor, p, [center,normal_vector,power])
  end

  def uni p, vector
    p = resolve(p)
    @current_object.f(:uni, p, vector)
  end
  
private
  def resolve p
    return @current_object[0]  if p==:first
    return @current_object[-1] if p==:last
    return [@current_object[-2], @current_object[-1]] if p==:last_two
    p    
  end

end
