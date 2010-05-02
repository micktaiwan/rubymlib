$KCODE = 'u'
require 'jcode'
require 'win32ole'
require 'date'
require '../MLib/word_analyser'

class OutlookConst
end

class Manager
  
  attr_reader :outlook, :outlook_namespace
  
  def initialize
    @outlook = WIN32OLE.new("Outlook.Application")
    @outlook_namespace = @outlook.GetNamespace("MAPI")
    WIN32OLE.const_load(@outlook, OutlookConst)
    @identifiers = Hash.new
    @words = WordAnalyser.new
  end
  
  def print_ole_methods(o)
    puts '==========================================='
    o.ole_methods.each { |m|
      print "#{m} : "
      begin
        eval "puts o.#{m.to_s.downcase}.to_s[0..80]"
      rescue Exception => e
        puts e.class
      end
    }
  end
  
  def get_folder_full_path(f)
    path = ""
    begin
      while (f.name != nil )#'Personal Folders') # f != nil marche pas
        path = f.name + "/" + path
        f = f.parent
      end
    rescue
    end
    path
  end
  
  def list_all_unread_mails(folders=['Personal Folders/Inbox'])
    folders.each { |name|
      f = get_folder(name)
      list_unread_mails(f)
    }
  end
  
  def list_unread_mails(folder=nil)
    folder = @outlook_namespace.GetDefaultFolder(OutlookConst::OlFolderInbox) if folder == nil
    puts "Unread emails in #{folder.name}: #{folder.unreaditemcount}"
    @identifiers[folder.name] = folder.entryid
    i = 0
    folder.items.each do |item|
      next if item.unread == false
      case item.messageclass
        when 'IPM.Note'
        puts "   #{item.sendername} : #{item.subject}"
        when 'IPM.TaskRequest.Accept'
        puts "   Accept : #{item.subject}"
      else
        puts "   ******* unknown message class: #{item.messageclass}"
        puts "   #{item.subject}"
      end
    end
  end
  
  # set to b the 'read' status of all mail in the folder f
  def set_folder_read(folder_name, unread_status)
    folder_id = @identifiers[folder_name]
    f = @outlook_namespace.getfolderfromid(folder_id)
    f.items.each { |email|
      next if email.unread == unread_status
      email.unread = unread_status
      email.save
    }
  end
  
  def get_folder(path)
    folders = path.split('/')
    @children = @outlook_namespace.folders
    folders.each { |f|
      #puts "Searching for: #{f}"
      @children.each { |p|
        #puts "on #{p.name}"
        next if f != p.name
        @children = p.folders
        break
      }
    }
    @children.parent
  end
  
  def search_children_by_name(children,name)
    return [] if children.count == 0
    rv = []
    children.each { |p|
      next if p.name == 'Public Folders' # because it's too big
      rv << p if (p.name =~ /#{name}/i) != nil
      c = search_children_by_name(p.folders,name)
      c.each {|f| rv << f if f != []}			
    }
    #rv.each {|f| puts f.name}
    rv
  end            
  
  def search_folder_by_name(name, path='Personal Folders')
    search_children_by_name(@outlook_namespace.folders,name)
  end
  
  def list_all_folders(root='Personal Folders')
    root_folder = nil
    @outlook_namespace.folders.each { |folder|
      next if root != '' and folder.name != root
      root_folder = folder
      break
    }
    raise "didn't find #{root}" if root_folder == nil
    root_folder.folders.each { |folder|
      puts folder.name
    }
  end
  
  def list_calendar_items(_start,_end)
    f = @outlook_namespace.GetDefaultFolder(OutlookConst::OlFolderCalendar)
    arr = []
    #f.items.includerecurrences = true
    #puts f.items.count
    f.items.each { |item|
      #puts item.ole_methods
      #break
      i_date = Date.parse(item.start)
      str = "#{item.start} (#{item.organizer}) '#{item.subject}'" 
      if i_date == _start
        str = "=> " + str 
      else
        str = "   " + str 
      end
      arr << [i_date,str] if i_date >= _start-1
      #puts "#{item.start} (#{item.organizer}) '#{item.subject}'" #if Date.parse(f.items.item(x).start) >= _start-1
    }
    arr = arr.sort_by { |i| i[0]}
    arr.each { |i|
      puts i[1]
    }
  end
  
  def list_all_open_tasks
    f = @outlook_namespace.GetDefaultFolder(OutlookConst::OlFolderTasks)
    f.items.each { |t|
      puts "#{t.subject}. Status=#{t.status} (#{t.owner})" if t.status != 2
    }
  end
  
  def create_email
    @outlook.createitem(OutlookConst::OlMailItem)
  end
  
  # create a tree [[folder name,[children]], [folder name, [children]]]
  # input: a folder object
  def folder_tree_for(f)
    rv = []
    #return rv
    f.folders.each {|f|
      rv << [f, folder_tree_for(f)]
    }
    rv = rv.sort_by {|e| e[0].name}
    rv
  end
  
  # perform a search before building the tree
  # input: a folder name
  
  def folder_tree(name)
    rv = []
    roots = search_folder_by_name(name)
    roots.each { |r| 
      puts get_folder_full_path(r)
      rv << [r, folder_tree_for(r)]
    }
    rv = rv.sort_by {|e| e[0].name}
    rv
  end
  
  def todo
    @words.clear
    f = get_folder('Personal Folders/Inbox/0-todo - Urgent')
    f.items.each { |email|
      #puts email.body
      @words.add_text(email.body,'test')
    }
    i = 100
    @words.words_count.sort {|a,b| b[1]<=>a[1]}.each { |v|
      puts "#{v[0]}: #{v[1]}"
      i -= 1; break if i == 0
    }
  end
end
