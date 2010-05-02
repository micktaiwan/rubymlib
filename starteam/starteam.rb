require 'win32ole'


class StarTeam
  
  class File
    attr_accessor :name, :modified_time, :version, :description, :modified_by, :f
    def initialize(f, name,v,d, t, b)
      @f, @name, @modified_time, @version, @description, @modified_by = f, name, t,v,d, b
    end
  end
  
  
  def initialize(server, port)
    @server = WIN32OLE.new('Starteam.StServerFactory').create(server, port)    
  end
  
  def log_on(l,p)
    @server.logOn(l,p)
  end
  
  # get all files infos for a project
  def parse_project_files(project)
    @files = []
    @server.projects.each{ |p|
      next if project != '*' and project != p.name
      p.views.each { |v|
        parse_folder(v.rootfolder)
        #break
      }
    }
  end
  
  # display all files for a project
  # if the value is '*' then all projects files are listed
  def display_all_files(project)
    @server.projects.each{ |p|
      next if project != '*' and project != p.name
      puts p.name
      p.views.each { |v|
        puts "== View == #{v.name}"
        display_folder(v.rootfolder,2)
      }
    }
  end
  
  def display_last_modified_files(lim=20)
    i = 1
    @files.sort_by { |f| f.modified_time}.reverse.each { |f| 
      puts "#{f.name} (v#{f.version}, at #{f.modified_time} by #{f.modified_by})"
      i += 1
      break if i > lim
    }
  end
  
  def display_locked_files
    @files.each { |f| 
  	if f.f.locker != -1
  		u = @server.getuser(f.f.locker)
  		puts "#{f.name} by #{u.name}" 
  	end
    }
  end
  
  def disconnect
    @server.disconnect
  end
  
  #######
  private
  
  def parse_folder_files(folder)
    folder.getitems('File').each { |f|
      @files << StarTeam::File.new(f, f.name,f.contentversion,f.description, f.modifiedtime, @server.getuser(f.modifiedby).name)
    }
  end
  
  def parse_folder(folder)
    parse_folder_files(folder)
    folder.getitems('Folder').each { |f|
      parse_folder(f)
    }
  end
  
  
  def display_folder_files(folder, tab)
    folder.getitems('File').each { |f|
      puts "  "*tab + "#{f.name} (v#{f.contentversion}, #{f.description.split.join(' ')}, #{f.modifiedtime})"
    }
  end
  
  def display_folder(folder,tab)
    display_folder_files(folder,tab+1)
    folder.getitems('Folder').each { |f|
      puts "  "*tab + "+#{f.name}"
      display_folder(f,tab+1)
    }
  end
  
end
