# TODO: Manager les docs par versions (v�rifier qu'ils y sont dans depuis starteam)
# TODO: pour chaque delivery, v�rifier les binaires et docs livr�s
# TODO: pour chaque delivery �tablir une liste d'actions de v�rification. Example: en 4.0 test RDL avec Groupe 0 fait ?
# � faire dans PTM !!!!
require 'aibmanager'
require '../MLib/TextPrompt'

HELP =<<_END
ver: list product versions
verify: verify that all docs are present
q: quit
h: help
_END

class Prompt < TextPrompt
  
  def initialize
    @manager = AIBManager.new
  end
  
  def parse_command(c)
    case c
      when 'q'
      return 'break'
      when 'h'
      puts HELP
      when 'ver'
      v = @manager.versions
      puts "Versions: %s" % v.join(', ')
    when 'verify'
      @manager.verify
    else
      puts "Unknown command '#{c}'"
    end   
  end
  
end

puts 'AIBManager V0.1'
puts '\'h\' for help'
p = Prompt.new
p.start
