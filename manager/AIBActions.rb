# Usage: le fichier emails.txt dans le même repertoire doit contenir les emails, un par ligne

# TODO:
# - ecrire le last action id en blanc pour pouvoir générer des emails et ne pas les envoyer :)
# - pas beau: les dates vides pour les actions closed
# - les actions affichées seules sans classement par group doivent faire apparaitre le group dans la ligne

require "ftools"
require '../MLib/ExcelFile'
require 'Manager'

# all these constants (path) must be in a file conf.rb
# FROM        ='C:\\path_to\\Actions-LOS.xls'
# WORKINGFILE ='C:\\local_path_to\\Actions-LOS.xls'
# BACKUP      ='C:\\backup_path\\Actions-LOS.bak.xls'

require 'conf' #... required here

ACTIONCELL  =3
ASSIGNEDCELL=10
STATUSCELL  =17
RELATEDCELL =12
ENDDATECELL =8
IDCELL      =1
RESULTSCELL =4
GROUPCELL   =2
INITTARGETCELL=6
TARGETCELL  =7

DAYS = ['Dimanche','Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi']

class Action
   attr_accessor :action, :assigned, :status, :group, :end_date, :id, :results, :target
   
   def initialize
   end
   
   def status_to_text
      return case @status
      when 'in progress';     'in progress'
      when 'open';            'open       '
      when 'closed';          'closed     '
      when '';                'open       '
      else 'unknown status'
      end
   end

   def status_to_html
      return case @status
      when 'in progress'; '<i>in progress</i>'
      when 'open';        '<i>open</i>'
      when 'closed';      '<i>closed</i>'
      when '';            '<i>open</i>'
      else '<b>unknown status</b>'
      end
   end

   
end

class ActionManager

   def initialize
      @actions = []
      print 'copy action file from network (y/n) ? '
      if gets.chomp == 'y'
         File.copy(WORKINGFILE, BACKUP)
         File.copy(FROM, WORKINGFILE)
         puts 'Files copied'
      end
      parse(WORKINGFILE)
      puts 'File parsed'
   end

   def list_actions
      #@actions.each { |a|
      #   puts a.action
      #   puts a.status_to_text
      #   }
      @actions.sort_by{|a| [a.status_to_text,a.assigned]}.each { |a|
         puts "#{a.status_to_text} #{a.assigned}: #{a.action}" if a.status!='closed'
         }
   end
   
   def prepare_mail_body
      # read last number
      last = 0
      File.open('./last.txt').each { |line| last = line.to_i}
      puts "Last email last action id: #{last}"
      # new actions
      group = Hash.new([])
      str = ''
      new_last  = 0
      nb_total  = 0
      nb_closed = 0
      @actions.each { |a|
          group[a.assigned] += [a] if a.id > last
          # last action
          new_last = a.id if a.id > last
          # some stats
          nb_total  += 1
          nb_closed += 1 if a.status == 'closed'
          }
      body = "<u><b>New actions since last email</b></u><ul>"
      group.each { |group_txt,a_arr|
         str += "<b>#{group_txt}</b><ul>"
         a_arr.sort_by{|a| a.target=='' ? Date.today : a.target}.each { |a|
            str += "<b>#{a.group}</b>: (<i>#{a.status_to_html}</i>) #{display_days_to_target(a.target)} #{a.action}<br/>"
            str += "<ul><b>Progress:</b> #{a.results}</ul>" if a.results != ''
            }
         str += "</ul>"
         }
      if str == ''
         body += 'None' 
      else
         body += str
         print 'Reset counter ? '
         if gets.chomp == 'y'
            File.new('./last.txt','w') << new_last.to_s
         end
      end      
      body += "</ul><br/><br/>"
      # current actions
      group.clear
      body += "<u><b>Current actions</b></u><ul>"
      @actions.each { |a|
         group[a.group] += [a]
         }
      group.each { |group_txt,a_arr|   
         next if 0 == a_arr.inject(0) {|sum, a| sum + ((a.status=='closed')?0:1)}
         body += "<b>#{group_txt}</b><ul>"
         a_arr.each {|a|
            if a.status!='closed'
               body += "<b>#{a.assigned}</b>: (<i>#{a.status_to_html}</i>) #{display_days_to_target(a.target)} #{a.action}<br/>"
               body += "<ul><b>Progress:</b> #{a.results}</ul>" if a.results != ''
            end
            }
         body += "</ul>"
         }
      body += "</ul><br/><br/>"
      
      # action sorted by holder and target date
      body += "<u><b>Actions by deadline</b></u><ul>"
      group.clear
      @actions.each { |a|
         group[a.assigned] += [a]
         }
      group.each { |group_txt,a_arr|   
         next if 0 == a_arr.inject(0) {|sum, a| sum + ((a.status=='closed')?0:1)}
         body += "<b>#{group_txt}</b><ul>"
         a_arr.sort_by{|a| a.target=='' ? Date.today : a.target}.each { |a|
            if a.status!='closed'
               body += "<b>#{a.group}</b>: (<i>#{a.status_to_html}</i>) #{display_days_to_target(a.target)} #{a.action}<br/>"
               body += "<ul><b>Progress:</b> #{a.results}</ul>" if a.results != ''
            end
            }
         body += "</ul>"
         }
      body += "</ul><br/><br/>" 
	 
      # closed actions
      group.clear
      @actions.each { |a|
         group[a.end_date] += [a]
         }
      body += "<b><u>Closed actions of the last 7 days</b></u><ul>"
      body += "#{nb_closed}/#{nb_total} = <b>#{nb_closed*100/nb_total}%</b> of all actions closed<br/><br/>"
      i = 1
      group.sort.reverse.each { |group_txt,a_arr|   
         break if group_txt < Date.today - 7
         next if 0 == a_arr.inject(0) {|sum, a| sum + ((a.status!='closed')?0:1)}
         body += "<b>#{DAYS[group_txt.wday()]} #{group_txt.mday()}</b><ul>"
         a_arr.each {|a|
            if a.status=='closed'
               body += "<b>#{a.assigned}: (#{a.group})</b> #{a.action}<br/>"
               body += "<ul><b>Results:</b> #{a.results}</ul>" if a.results != ''
            end
            }
         body += "</ul>"
         }

      body += "</ul><br/><br/>"
      body += "<font size='-1'><i>Cet email est généré automatiquement depuis le fichier d'actions (voir Starteam: meta/other)<br/>"
      body
   end
   
   def send_mail
      outlook = Manager.new
      msg  = outlook.create_email
      File.open('./emails.txt').each_line { |line|
        line = line.chomp
        next if line == '' or line[0].chr == '#'
        msg.recipients.add(line)
        #puts line
        }
      msg.subject = "Actions "+Date.today.to_s
      msg.htmlbody = prepare_mail_body
      msg.recipients.each { |r|
           r.resolve
           }
      msg.save
   end
   
   def parse(file)
      excel = ExcelFile.new
      excel.open(file)
      begin
         i = 2
         while(true)
            action = excel.cells(i,ACTIONCELL).text
            break if(action == '')
            a = Action.new
            a.action = action
            a.assigned = excel.cells(i,ASSIGNEDCELL).text
            a.assigned = '---' if a.assigned == ''
            a.status = excel.cells(i,STATUSCELL).text
            a.status = 'open' if a.status != 'open' and a.status != 'in progress' and a.status != 'closed'
            a.group = excel.cells(i,GROUPCELL).text
            a.group = 'pas classé' if a.group == ''
            date = excel.cells(i,ENDDATECELL).text
            begin date = Date.parse(date,true); rescue; date = Date.today(); end
            a.end_date = date
            # target
            date = excel.cells(i,TARGETCELL).text
            date = excel.cells(i,INITTARGETCELL).text if date == ''
            begin date = Date.parse(date,true); rescue; date = ''; end
            a.target = date
            
            a.id = excel.cells(i,IDCELL).text.to_i
            a.results = excel.cells(i,RESULTSCELL).text
            @actions << a
            i += 1
         end
      ensure
         excel.close
      end
   end
   
   def display_days_to_target(d)
      return '' if d == ''
      nb = days_diff(d)
      return '' if nb > 20
      return "<b><font color='#888888'>#{nb} days:</font></b> " if nb > 10
      return "<b><font color='#FF8800'>#{nb} days:</font></b> " if nb > 0
      return "<b><font color='red'>today:</font></b> " if nb == 0
      return "<b><font color='red'>#{nb} days:</font></b> "
   end
   
   def days_diff(d)
      now = Date.today
      diff = d - now
      hours, mins, secs, ignore_fractions = Date::day_fraction_to_time(diff)
      hours / 24
   end
   
   
end

am = ActionManager.new
#am.list_actions
print 'Send mail ? '
if gets.chomp == 'y'
   am.send_mail
end
   
