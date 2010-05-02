=begin

Choose initial population
Evaluate the fitness of each individual in the population
Repeat until termination: (time limit or sufficient fitness achieved)
  Select best-ranking individuals to reproduce
  Breed new generation through crossover and/or mutation (genetic operations) and give birth to offspring
  Evaluate the individual fitnesses of the offspring
  Replace worst ranked part of population with offspring

=end

class Population < Array

  # subclasses must define
  # fitness(individual): calculate the fitness of the individual between [0..inf[. 0 is perfect.
  # breed(ind1,ind2): given 2 individuals, give birth to a offspring

  def generate
    selection
    breed_all
  end

  def global_fitness
    inject(0) { |rv,i| rv += fitness(i)}.to_f / size
  end
  
private

  def selection
    self.replace sort_by { |i| fitness(i)}
  end
      
  def breed_all
    for i in (0..size/2)
      self[size/2+i] = breed(self[i],self[i+1])      
    end
  end
  
end

