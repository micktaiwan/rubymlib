require 'ftools'
require 'logger'
require 'config'


class AIBManager
  
  def initialize
    @log = Logger.new(STDOUT)
    @log.level = Logger::WARN
  end
  
  # return a array of version numbers
  # puts warnings if folders do not follow the vN.N naming convention
  def versions
    rv = []
    f = Dir.open(CONFIG[:paths][:ref]+'Binaries')
    f.each { |d|
      next if d=='.' or d=='..'
      @log.warn("folder name does not follow convention v.N.N: '#{d}'") and next if not d =~ /^v\d(.\d)+$/
      rv << d      
    }
    rv
  end
  
  def verify
    out = File.new('./Rapport.html','w')
    out.puts "<html><head><style type='text/css' title='currentStyle' media='screen'>@import 'styles.css';</style></head><body>"
    verify_sys(out)
    out.puts "</body></html>"
    out.close
  end
  
  # verify that each doc is here
  # verify that each doc respects naming convention
  def verify_sys(out)
    out.puts '==== Verifying system docs locally (you should have checked out all Starteam docs)<br/><br/>'
    # verify directories
    r = CONFIG[:paths][:sys]
    mkdir(r)
    CONFIG[:docs][:sys][:single].map{|doc| doc[:dir]}.uniq.sort.each { |dir| 
      mkdir(r+dir)
      # for each dir verify that all docs are here
      out.puts "<h2>" + dir + "</h2><ul>"
      get_doc_for_sys_dir(dir).each { |hash|
        out.print "   " + hash[:name] + "... "
        file_name = dir_has_file(r+dir,hash[:regexp])
        if file_name != nil
          out.puts "OK (#{file_name})<br/>" # ok mais pour quelle version ?
        else
          out.puts '<strong>Not found</strong><br/>'
        end
      }
      out.puts "</ul>"
    }
    puts "Rapport generated"
  end

  ##############################################
  private
  
  # create directories and catch exceptions
  def mkdir d
    begin
      Dir.mkdir(d)
      @log.debug "created directory #{d}"
    rescue
    end
  end
  
  # read CONFIG and return a list of regexp for a given dir
  def get_doc_for_sys_dir(dir)
    rv = []
    CONFIG[:docs][:sys][:single].each {|doc|
      rv << {:name => doc[:name],:regexp => doc[:conv]} if doc[:dir] == dir
    }
    rv
  end
  
  def dir_has_file(dir,regexp)
    return nil if regexp.class.to_s != "Regexp"
    Dir.open(dir).each {|file|
      next if file=='.' or file=='..'
      return file if file =~ regexp
    }
    return nil
  end
  
end
