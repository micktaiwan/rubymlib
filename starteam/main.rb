require 'starteam'
require 'config'

st = StarTeam.new(CONFIG[:server_name], CONFIG[:server_port])
st.log_on(CONFIG[:login],CONFIG[:pwd])
st.parse_project_files(CONFIG[:project_name])
puts "Locked files"
puts
st.display_locked_files
puts
puts "Last Modified files"
puts
st.display_last_modified_files(50)
puts
puts "All files"
puts
st.display_all_files(CONFIG[:project_name])
st.disconnect
