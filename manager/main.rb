# Manager les docs par versions (vérifier qu'ils y sont dans depuis starteam)
# Manager les emails todo dans Outlook

require '../MLib/TextPrompt'
require 'Manager'
require 'enumerator'

HELP =<<_END
u: list unread mails
q: quit
h: help
r: set status of all mails in a folder (prompt) to read
s: search a folder by name (prompt)
c: list calendar items
tree: write a file containing the folder tree for a folder
tasks: list tasks
test: run unit tests
todo: list todo mails words
_END


class Prompt < TextPrompt
  
  def initialize
    @manager = Manager.new
  end
  
  def output_tree(tree, tab)
    #puts tree.size
    return if tree == []
    tree.each { |f_children|
      f = f_children[0]
      children = f_children[1]
      #puts "f=#{f}, children=#{children}"
      tab.times { @file << "\t" }
      @file << f.name + "\n"
      output_tree(children,tab+1)
    }
  end
  
  def parse_command(c)
    case c
      when 'q'
      return 'break'
      when 'h'
      puts HELP
      when 'test'
      run_utests
      when 'u'
      folders = ['Personal Folders/Inbox','Personal Folders/01_Echanges/10_Perso/poker','Personal Folders/01_Echanges/08_SQLI/forward']
      @manager.list_all_unread_mails(folders)
      when 'r'
      print "folder name: "
      name = gets.chomp
      @manager.set_folder_read(name,false) #unread status = false
      when 's'
      print "folder name: "
      name = gets.chomp
      rv = @manager.search_folder_by_name(name)
      rv.each { |f| puts @manager.get_folder_full_path(f) }
      when 'tree' # output un tree du folder
      print "folder name: "
      name = gets.chomp
      tree = @manager.folder_tree(name)
      @file = File.open('tree.txt','w')
      output_tree(tree,0)
      @file.close
      when 'c'
      @manager.list_calendar_items(Date.today,'')
      when 'tasks'
      @manager.list_all_open_tasks
      when 'todo'
      @manager.todo
    else
      puts "Unknown command '#{c}'"
    end   
  end
  
  def run_utests
    test_outlook
  end
  
  def test_outlook
    #puts 
    #@manager.list_all_unread_mails
    folder = @manager.outlook_namespace.GetDefaultFolder(OutlookConst::OlFolderInbox)
    puts folder.description
    #puts ex.ole_methods
    puts folder.ole_methods
  end
  
end

puts 'Manager V0.1'
p = Prompt.new
p.start
