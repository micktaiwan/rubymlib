# TODO: Manager les docs par versions (vérifier qu'ils y sont dans depuis starteam)
# TODO: pour chaque delivery, vérifier les binaires et docs livrés
# TODO: pour chaque delivery établir une liste d'actions de vérification. Example: en 4.0 test RDL avec Groupe 0 fait ?
# à faire dans PTM !!!!
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
