# TODO: lister les DMD à analyser prioritairement (mettre une prio dans les comments ?)
# TODO: prendre les taches dans les commentaires des AM
# TODO: sortir les impacts des analyses sur toutes les DM analysées
# TODO: indicateurs

# with ruby 1.8.6, we do not need these require anymore
#require 'Date'
#require 'ftools'

# change this constant to indicate where the GEMO Excel extract is.
# The GEMO extract must contains all DM, OM and AM (it's a GEMO export option)
GEMO_PATH  = 'C:\Home\FAIVRE_MACON\Mickael\Airbus\extract_gemo.xls'

require 'enumerator'
require '../MLib/ExcelFile'
require '../MLib/TextPrompt'
#require '../ReqTracking/ReqTracker'

class OM
  
  attr_accessor :id, :title
  
  def to_s
    "##{id} : #{title}"
  end
  
end


class DMD
  attr_accessor :id, :component, :source, :issuer, :title, :comments,
  :severity, :criticality, :priority, :status, :target, :type, :cost, :om, :analyse,
  :analyse_status, :ccb_status, :workload, :last_user, :last_update
  def to_s
      "##{id}\t#{status}\tP#{priority}\t#{title}"
  end
  
end

class DMDList
  
  def initialize
    @lists = Array.new
  end
  
  def create
    l = Array.new
    @lists << l
    l
  end
  
  def disp_summary
    nb = @lists.size
    puts "#{nb} DMD lists"
    @lists.each { |l|
      puts "#{l.size} DMD:"
      l.each { |dmd| puts dmd }
    }
  end
  
  def last
    @lists.last
  end
  
  def clear
    @lists.clear
  end
  
  # take the last list and search the DM by dmd number (source)
  def search_by_dmd_number dmd
    last.find {|dm| (dm.source =~ /^(DMD|DMD LOS) #{dmd}$/) != nil}
  end
  
end

class SCB < TextPrompt
  
  def initialize
    super
    #@master     = tmp+'SCB_DMD_Master.xls'
    #@copy       = tmp+'SCB_'
    #@backup_dir = tmp
    #@backup_file= @backup_dir + 'Master_backup.xls'
    @scb_date   = Date.today.to_s
    @excel      = ExcelFile.new
    @lists = DMDList.new
    @dmds = nil
    @omlist = {}
    display_help
    reset
  end
  
  def display_help
    puts "CCB Manager 0.1"
    puts "sum:    create a summary"
    puts "s:      search DM or DMD by number"
    puts "g:      find_missing_dm"
    puts "closed: display closed dmd not decided still in the Master"
    puts "fg:     fill Master from grefie"
    puts "fgl:    fill Master from grefie from a list of DMD"
    puts "reset:  reparse the gemo extract"
  end
  
  def parse_command(c)
    case c
      when 'q'
      return 'break'
      when 'sum'
      create_summary
      when 's'
      print "number: "
      n = gets.chomp
      search_dm n
      when 'g'
      display_missing_dm
      when 'reset'
      reset
      when 'closed'
      display_closed_dmd
      when 'fg'
      fill_from_grefie
      when 'fgl'
      print "list of dmd separated by spaces: "
      dmds = gets.chomp
      fill_from_grefie 0,dmds.split(' ')
    else puts "Unknown command: #{c}"
    end
  end
  
  def enter_scb_date
    print "Enter SCB date [#{today}]: "
    scb_date = gets.chomp
    return if scb_date == ''
    @scb_date = scb_date
  end
  
  def freeze
    print 'Create a freeze (y/n) ? '
    return if gets.chomp != 'y'
    enter_scb_date
    # copy master
    @working = @copy+@scb_date+'.xls'
    File.copy(@master, @working)
  end
  
  def backup
    # backup
    return # do nothing for now
    print 'Create a backup (y/n) ? '
    return if gets.chomp != 'y'
    File.copy(@master, @backup_file)
  end
  
  def insert_value_with_exception(line,col,v)
    t = @excel.cells(line,col).value
    raise "value exists at line #{line}, col #{col}" if t != nil and t != ''
    @excel.cells(line,col).value = v
  end
  
  def insert_in_master_backup(dmd, line)
    puts "inserting at #{line}"
    insert_value_with_exception(line,1,"No DM yet")
    insert_value_with_exception(line,2,"LOS")
    insert_value_with_exception(line,3,"DMD #{dmd[Dmd::NUMBER]}")
    insert_value_with_exception(line,5,dmd[Dmd::TITLE])
    insert_value_with_exception(line,6,dmd[Dmd::DESCR].gsub('|#|',"\n")+"\n\nFull description:\n"+dmd[Dmd::FULLDESCR].gsub('|#|',"\n"))
  end
  
  def search_dm n
    rt = ReqTracker.new
    rt.dmd.list.each { |line|
      next if (line[Dmd::NUMBER] != n)
      puts "#{line[Dmd::NUMBER]}: (#{line[Dmd::STATUS]}) #{line[Dmd::TITLE]}"
    }      
    dmd = @lists.search_by_dmd_number(n)
    puts "#{dmd.id}: #{dmd.source} (#{dmd.status}) #{dmd.title}" if dmd != nil
  end
  
  # find closed DMD that are in Master
  def find_closed_dmd
    r = []
    rt = ReqTracker.new
    rt.dmd.list.each { |line|
      next if (line[Dmd::STATUS] != "CLOSED" and line[Dmd::STATUS] != "NO ACTION")
      dmd_id = line[Dmd::NUMBER]
      dmd = @lists.search_by_dmd_number(dmd_id)
      r << dmd if(dmd != nil and dmd.status != 'Decided' and dmd.status != 'Closed' and dmd.status != 'Rejected')
    }      
    r
  end
  def display_closed_dmd
    find_closed_dmd.each {|dmd|
      puts "DMD closed: #{dmd.source}\t(DM #{dmd.id})\t#{dmd.title}\tStatus=#{dmd.status}"
    }
  end
  def closed_dmd_html
    r = ''
    find_closed_dmd.each {|dmd|
      r += "<li><span class='dmd_source'>#{dmd.source}</span> <span class='dmd_id'>(DM #{dmd.id})</span> <span class='dmd_title'>#{dmd.title}</span> <span class='dmd_status'>#{dmd.status}</span></li>"
    }
    r
  end
  
  # get info from grefie export and complete the Master
  # max: max number of dmd to export, all if 0
  # dmd_list (array of dmd number): export only these dmd
  def fill_from_grefie(max = 10, dmd_list = [])
    puts "max #{max} missing DMD" if max > 0
    i = 0
    rt = ReqTracker.new
    begin
      @excel.open(@backup_file)
      @excel.select(3)
      excel_line = 2
      excel_line += 1 while g(excel_line,1)!='' or g(excel_line,2)!=''
      rt.dmd.list.each { |line|
        if line[Dmd::STATUS] != "OPEN"
          puts "#{line[Dmd::NUMBER]} is not open (#{line[Dmd::STATUS]})" if (dmd_list != [] and dmd_list.member?(line[Dmd::NUMBER]))
          next
        end
        next if (dmd_list != [] and not dmd_list.member?(line[Dmd::NUMBER]))
        dmd_id = line[Dmd::NUMBER]
        if(@lists.search_by_dmd_number(dmd_id) == nil)
          puts "Not in master: #{dmd_id} #{line[Dmd::TITLE]}"
          insert_in_master_backup(line,excel_line)
          excel_line += 1
          i += 1
          break if (max != 0 and i >= max) or (dmd_list != [] and i>dmd_list.size)
        end
      }      
    ensure
      #@excel.save
      @excel.close
    end
  end
  
  # display GEMO dm not in the Master
  def display_missing_dm max=10
    puts "Displaying max #{max} missing DM" if max > 0
    rt = ReqTracker.new
    i = 0
    rt.sumo.list.each { |line|
      id = line[Sumo::NUMBER]
      dmds = @lists.last
      if dmds.find { |d| d.id.to_s==id.to_s} == nil
        puts "DM #{id} not found"
        i += 1
        break if max != 0 and i >= max
      end
    }
  end
  
  # TODO: get info from gemo export and complete the Master
  def fill_from_gemo
  end
  
  # TODO: copy SCB actions to main SWN Action file
  def copy_actions
  end
  
  # TODO: find duplicates DM
  def find_duplicates
    @dmds = @lists.last
  end
  
  def g(l,c)
    @excel.cells(l,c).text
  end
  
  def read_lines
    #puts "new"
    #@excel.select(3)
    line = 2
    while(true)
      dmd = DMD.new
      
      dmd.id, dmd.title, dmd.severity, dmd.criticality, dmd.priority,
      dmd.analyse_status, dmd.status, dmd.ccb_status, dmd.om, dmd.source,
      dmd.comments, dmd.workload, dmd.last_user, dmd.last_update, dmd.type =
      g(line,2),g(line,5),g(line,12),g(line,13),g(line,19),
      g(line,15), g(line,9),g(line,16),g(line,32),g(line,22),
      g(line,40), g(line,30), g(line,14), g(line,13), g(line,4)
      # 1:  Product, DM, Index, Type, Title, Subset, Detected version, Author, Progress state, Creation date,
      # 11: Abandoned date , Close date, Last modif. Date, Last user , Analysis state, CCB State, Severity, Criticity, Priority, Detection step,
      # 21: Reference type, Reference, Description, To Test, Limitation, Skirting, Operational impact, Interaction detected, OA, Workload,
      # 31: Workload - Comments, OM, Take into account state, Verification state, Synthetic description, Complete description, Impact of correction, Recommendations, Tests performed, Comments
      
      dmd.priority = 'TBD' if dmd.priority == ''
      dmd.last_update =  g(line,10) if dmd.last_update == 'null'
      @dmds << dmd
      #puts dmd
      line += 1
      break if @excel.cells(line,1).text == '' and @excel.cells(line,2).text == ''
      #print '.'
    end
    #puts
  end
  
  # parse the gemo extract
  def parse_gemo
    print "Parsing the gemo extract... "
    begin
      @dmds = @lists.create
      @excel.open(GEMO_PATH)
      read_lines
      read_om
    ensure
      @excel.close
    end
    puts "done"
  end
  
  def read_om
    @excel.select(3)
    line = 2
    while(true)
      @omlist[g(line,2)] = g(line,4) # id => title
      line += 1
      break if @excel.cells(line,1).text == ''
    end
  end
  
  # input: dmds: hash of prio=>DMD list
  # output: html
  def priority_html(dmds)
    html = ''
    dmds.each { |title,list|
      html += "<b>#{title}</b><br/>\n<ul>"
      list.each { |dmd|
        html += "<li><span class=\"dmd_id\">#{dmd.id}</span> <span class=\"dmd_source\">#{dmd.source}</span> <span class=\"dmd_status\">("
        html += "#{dmd.ccb_status}"
        html += ")</span> <span class=\"dmd_analyse_status\">("
        html += "<span class=\"open\">" if dmd.analyse_status == 'Open'
        html += "#{dmd.analyse_status}"
        html += "</span>" if dmd.analyse_status == 'Open'
        html += ")</span> <span class=\"dmd_om\">#{dmd.om}</span>: <span class=\"dmd_title\">#{dmd.title}</span><ul><span class=\"dmd_actions\">#{dmd.comments}</span><span class=\"dmd_analyse\">#{dmd.analyse}</span></ul></li>\n"
      }
      html += "</ul>\n"
    }
    #puts html
    html
  end
  
  # input: @dmds: the DMD list
  # output: a hash of prio=>DMD list
  def priority_dmd
    tmp = Hash.new
    @dmds.each { |dmd|
      next if (dmd.type[0..2]!= 'ANO' or dmd.analyse_status == 'Analysed' or dmd.status != 'Open' or dmd.om != '')
      tmp[dmd.priority] = [] if tmp[dmd.priority]==nil
      tmp[dmd.priority] << dmd
    }
    tmp
  end
  
  def priority_evo
    tmp = Hash.new
    @dmds.each { |dmd|
      next if (dmd.type[0..2]== 'ANO' or dmd.analyse_status == 'Analysed' or dmd.status != 'Open' or dmd.om != '')
      tmp[dmd.priority] = [] if tmp[dmd.priority]==nil
      tmp[dmd.priority] << dmd
    }
    tmp
  end
  
  def analysed_html(dmds)
    html = ''
    dmds.each { |title,list|
      html += "<b>#{title}</b><br/>\n<ul>"
      list.each { |dmd|
        html += "<li>#{dmd.workload}d. <span class=\"dmd_id\">#{dmd.id}</span> <span class=\"dmd_source\">#{dmd.source}</span> <span class=\"dmd_status\">(#{dmd.ccb_status})</span> <span class=\"dmd_analyse_status\">(#{dmd.analyse_status})</span> <span class=\"dmd_om\">#{dmd.om}</span>: <span class=\"dmd_title\">#{dmd.title}</span><ul><span class=\"dmd_actions\">#{dmd.comments}</span><span class=\"dmd_analyse\">#{dmd.analyse}</span></ul></li>\n"
      }
      html += "</ul>\n"
    }
    #puts html
    html
  end
  
  def analysed_dmd
    tmp = Hash.new
    @dmds.each { |dmd|
      next if (not (dmd.analyse_status == 'Analysed' or dmd.analyse_status == 'Closed') or dmd.om != '' or dmd.ccb_status=='Rejected')
      tmp[dmd.priority] = [] if tmp[dmd.priority]==nil
      tmp[dmd.priority] << dmd
    }
    tmp
  end
  
  def workload_dmd
    tmp = Hash.new
    @dmds.each { |dmd|
      next if (not (dmd.workload != '0' and dmd.analyse_status != 'Analysed'))
      tmp[dmd.priority] = [] if tmp[dmd.priority]==nil
      tmp[dmd.priority] << dmd
    }
    tmp
  end
  
  # input: dmds: prio=>DMD list
  # output: html
  def decided_html(dmds)
    html = ''
    dmds.each { |om_id,list|
      html += "<b>#{@omlist[om_id]}</b><br/>\n<ul>"
      list.each { |dmd|
        html += "<li><span class=\"dmd_id\">#{dmd.id}</span> <span class=\"dmd_source\">#{dmd.source}</span>: <span class=\"dmd_title\">#{dmd.title}</span></li>\n"
      }
      html += "<br/></ul>\n"
    }
    #puts html
    html
  end
  
  # input: @dmds: the DMD list
  # output: hash of prio=>DMD list
  def decided_dmd
    tmp = Hash.new
    @dmds.each { |dmd|
      next if dmd.om == ''
      tmp[dmd.om] = [] if tmp[dmd.om]==nil
      tmp[dmd.om] << dmd
    }
    tmp
  end
  
  
  def last_updated_html(dmds)
    html = ''
    dmds.each { |dmd|
      html += "<li>#{dmd.last_update} <span class=\"dmd_id\">#{dmd.id}</span> <span class=\"dmd_source\">#{dmd.source}</span>: <span class=\"dmd_title\">#{dmd.title}</span> #{dmd.last_user}</li>\n"
    }
    #puts html
    html
  end
  
  # input: @dmds: the DMD list
  # output: hash of prio=>DMD list
  def last_updated_dmd
    @dmds.sort_by {|d| d.last_update}.reverse
  end
  
  # input: @dmds: the DMD list
  # output: hash containing count of dmd by priority
  def prios_hash
    tmp = Hash.new(0)
    @dmds.each { |dmd|
      next if (dmd.analyse_status=='Analysed' or dmd.status != 'Open' or dmd.om != '')
      tmp[dmd.priority] += 1
    }
    tmp
  end
  
  # open DMD report 
  def sas_report
    ano = Hash.new(0)
    evo = Hash.new(0)
    @dmds.each { |dmd|
      next if (dmd.status != 'Open' or dmd.om != '')
      if(dmd.type[0..2]== 'ANO')
        ano[dmd.priority] += 1
      else
        evo[dmd.priority] += 1
      end
    }
    [ano,evo]
  end
  
  
  def parse_actions
    tmp = Hash.new
    @dmds.each { |dmd|
      next if dmd.comments == '' or dmd.comments == nil
      arr = dmd.comments.scan(/@[A-Z]{3,3}:\w*.*/)
      #puts "wrong action format: #{dmd.comments}" and next if arr == []
      arr.each { |a|
        name    = a[1..3].strip
        action  = a[5..-1].strip
        tmp[name] = [] if tmp[name] == nil
        tmp[name] << [action, dmd]
      }
    }
    # sort actions by dmd priority
    tmp.each { |who,actions|
      tmp[who] = actions.sort_by { |a| a[1].priority}
    }
    tmp
  end
  
  def actions_html
    str = ""
    parse_actions.each {|who, value|
      str += who
      str += "<ul>\n"
      value.each { |a|
        action = a[0]
        dmd = a[1]
        str += "<li><span class=\"dmd_prio\">#{dmd.priority}</span> <span class=\"dmd_id\">#{dmd.id}</span> <span class=\"dmd_source\">(#{dmd.source})</span> <span class=\"dmd_title\">#{dmd.title}</span> <span class=\"dmd_actions\">#{action}</span></li>\n"
      }
      str += "</ul>\n"
    }
    str
  end
  
  def prio_diff
    rv = []
    rt = ReqTracker.new
    rt.dmd.list.each { |line|
      next if line[Dmd::STATUS] != "OPEN"
      dmd_id = line[Dmd::NUMBER]
      dmd = @lists.search_by_dmd_number(dmd_id)
      if(dmd != nil)
        next if dmd.status == 'Rejected' or dmd.status == 'Decided' or dmd.status == 'Closed'
        p = line[Dmd::OPENFIELD1]
        p = 'not priorized' if p == ''
        rv << [dmd, p, line[Dmd::TITLE]] if dmd.priority != p and dmd.priority != 'TBD'
      end
    }      
    rv.sort_by { |i| i[0].priority<=>i[1]}
  end
  
  def prio_diff_html
    str = ''
    prio_diff.each { |i|
      dmd = i[0]
      str += "<li><span class=\"dmd_prio\">#{dmd.priority}</span> != #{i[1]} <span class=\"dmd_id\">#{dmd.id}</span> <span class=\"dmd_source\">(#{dmd.source})</span> <span class=\"dmd_title\">#{dmd.title}</span> <b>DMD:</b> #{i[2]}</li>\n"
    }
    str
  end
  
  # create html summary from memory structures
  def create_html_summary
    puts "Creating HTML..."
    @dmds = @lists.last
    @html  = '<html>'
    @html += '<head><link rel="stylesheet" href="styles.css"></head>'
    @html += '<body>'
    @html += "<h3>Actions</h3>\n<ul>"
    @html += actions_html
    @html += "</ul>\n"
    #@html += "<h3>Prios diff</h3>\n<ul>"
    #@html += prio_diff_html
    #@html += "</ul>\n"
    #@html += "<h3>Closed DMD</h3>\n<ul>"
    #@html += closed_dmd_html
    #@html += "</ul>\n"
    @html += "<h3>Open DM</h3>"
    ano, evo = sas_report
    @html += "<table><tr><td>Nature of changes</td><td>P0</td><td>P1</td><td>P2/P3</td><td>Total</td></tr>
    <tr><td>Anomalies</td><td>#{ano['0']}</td><td>#{ano['1']}</td><td>#{ano['2']+ano['3']}</td><td>#{ano['0']+ano['1']+ano['2']+ano['3']}</td></tr>
    <tr><td>Evolutions</td><td>#{evo['0']}</td><td>#{evo['1']}</td><td>#{evo['2']+evo['3']}</td><td>#{evo['0']+evo['1']+evo['2']+evo['3']}</td></tr>
    <tr><td>Total</td><td>#{ano['0']+evo['0']}</td><td>#{ano['1']+evo['1']}</td><td>#{ano['2']+ano['3']+evo['2']+evo['3']}</td><td>#{ano['0']+evo['0']+ano['1']+evo['1']+ano['2']+ano['3']+evo['2']+evo['3']}</td></tr>
    <table>"
    count = prios_hash
    @html += "<h3>Non analysed DMD, by priority</h3><ul>\n"
    @html += "<b>Stats</b><ul>TBD: #{count['TBD']}<br/>P0: #{count['0']}<br/>P1: #{count['1']}<br/>P2: #{count['2']}<br/>P3: #{count['3']}<br/></ul>\n"
    @html += "#{priority_html(priority_dmd)}</ul>\n"
    @html += "<h3>Evo</h3>\n<ul>#{priority_html(priority_evo)}</ul>\n"
    @html += "<h3>Analysed but not batched DMD</h3>\n<ul>#{analysed_html(analysed_dmd)}</ul>\n"
    @html += "<h3>Has workload but not 'analysed' DMD</h3>\n<ul>#{analysed_html(workload_dmd)}</ul>\n"
    @html += "<h3>Decided DMD</h3>\n<ul>#{decided_html(decided_dmd)}</ul>\n"
    @html += "<h3>Last updated</h3>\n<ul>#{last_updated_html(last_updated_dmd)}</ul>\n"
    @html += '</body>'
    @html += '</html>'
  end
  
  # create a html summary from backup file
  def create_summary
    puts "Creating a summary..."
    #@lists.disp_summary
    create_html_summary
    file = File.open('test.html','w')
    file << @html
    file.close
  end
  
  # ask todo a backup, delete all dmd lists and reparse the backup file
  def reset
    #backup
    @lists.clear
    parse_gemo
  end
  
end

s = SCB.new
s.start
