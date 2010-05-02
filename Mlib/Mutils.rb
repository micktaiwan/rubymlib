require 'Win32API'

def get_sub_dir(dir, list)

	Dir.foreach(dir) { |d|
		next if d=='.' or d == '..'
		begin
			file = File.open(dir+d).close
		rescue
			d = dir+d+"\\"
			list << d
			get_sub_dir(d, list)
		end
		}
end

def set_autocompletion
	Win32::Registry.create
	shell.RegWrite("HKEY_LOCAL_MACHINE","\\SOFTWARE\\Microsoft\\Command Processor\\CompletionChar", 9, "REG_DWORD")
	wshell.RegWrite("HKEY_LOCAL_MACHINE","\\SOFTWARE\\Microsoft\\Command Processor\\PathCompletionChar", 9, "REG_DWORD")
end
