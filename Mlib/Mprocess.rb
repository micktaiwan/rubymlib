 require 'Win32API'

NORMAL_PRIORITY_CLASS = 0x00000020
STARTUP_INFO_SIZE = 68
PROCESS_INFO_SIZE = 16
SECURITY_ATTRIBUTES_SIZE = 12

ERROR_SUCCESS = 0x00
FORMAT_MESSAGE_FROM_SYSTEM = 0x1000
FORMAT_MESSAGE_ARGUMENT_ARRAY = 0x2000

HANDLE_FLAG_INHERIT = 1
HANDLE_FLAG_PROTECT_FROM_CLOSE =2

STARTF_USESHOWWINDOW = 0x00000001
STARTF_USESTDHANDLES = 0x00000100

def raise_last_win_32_error
  errorCode = Win32API.new("kernel32", "GetLastError", [], 'L').call
  if errorCode != ERROR_SUCCESS
    params = [
      'L', # IN DWORD dwFlags,
      'P', # IN LPCVOID lpSource,
      'L', # IN DWORD dwMessageId,
      'L', # IN DWORD dwLanguageId,
      'P', # OUT LPSTR lpBuffer,
      'L', # IN DWORD nSize,
      'P', # IN va_list *Arguments
    ]

    formatMessage = Win32API.new("kernel32", "FormatMessage", params, 'L')
    msg = ' ' * 255
    msgLength = formatMessage.call(FORMAT_MESSAGE_FROM_SYSTEM +
      FORMAT_MESSAGE_ARGUMENT_ARRAY, '', errorCode, 0, msg, 255, '')

    msg.gsub!(/\000/, '')
    msg.strip!
    raise msg
  else
    raise 'GetLastError returned ERROR_SUCCESS'
  end
end

def create_pipe # returns read and write handle
  params = [
    'P', # pointer to read handle
    'P', # pointer to write handle
    'P', # pointer to security attributes
    'L'] # pipe size

  createPipe = Win32API.new("kernel32", "CreatePipe", params, 'I')

  read_handle, write_handle = [0].pack('I'), [0].pack('I')
  sec_attrs = [SECURITY_ATTRIBUTES_SIZE, 0, 1].pack('III')

  raise_last_win_32_error if createPipe.Call(read_handle,
    write_handle, sec_attrs, 0).zero?

  [read_handle.unpack('I')[0], write_handle.unpack('I')[0]]
end

def set_handle_information(handle, flags, value)
  params = [
    'L', # handle to an object
    'L', # specifies flags to change
    'L'] # specifies new values for flags

  setHandleInformation = Win32API.new("kernel32",
    "SetHandleInformation", params, 'I')
  raise_last_win_32_error if setHandleInformation.Call(handle,
    flags, value).zero?
  nil
end

def close_handle(handle)
  closeHandle = Win32API.new("kernel32", "CloseHandle", ['L'], 'I')
  raise_last_win_32_error if closeHandle.call(handle).zero?
end

def create_process(command, stdin, stdout, stderror)
  params = [
    'L', # IN LPCSTR lpApplicationName
    'P', # IN LPSTR lpCommandLine
    'L', # IN LPSECURITY_ATTRIBUTES lpProcessAttributes
    'L', # IN LPSECURITY_ATTRIBUTES lpThreadAttributes
    'L', # IN BOOL bInheritHandles
    'L', # IN DWORD dwCreationFlags
    'L', # IN LPVOID lpEnvironment
    'L', # IN LPCSTR lpCurrentDirectory
    'P', # IN LPSTARTUPINFOA lpStartupInfo
    'P']  # OUT LPPROCESS_INFORMATION lpProcessInformation

  startupInfo = [STARTUP_INFO_SIZE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW, 0,
    0, 0, stdin, stdout, stderror].pack('IIIIIIIIIIIISSIIII')

  processInfo = [0, 0, 0, 0].pack('IIII')
  command << 0

  createProcess = Win32API.new("kernel32", "CreateProcess", params, 'I')
  raise_last_win_32_error if createProcess.call(0,
    command, 0, 0, 1, 0, 0, 0, startupInfo, processInfo).zero?

  hProcess, hThread, dwProcessId, dwThreadId = processInfo.unpack('LLLL')

  close_handle(hProcess)
  close_handle(hThread)

  [dwProcessId, dwThreadId]
end

def write_file(hFile, buffer)
  params = [
    'L', # handle to file to write to
    'P', # pointer to data to write to file
    'L', # number of bytes to write
    'P', # pointer to number of bytes written
    'L'] # pointer to structure for overlapped I/O

  written = [0].pack('I')
  writeFile = Win32API.new("kernel32", "WriteFile", params, 'I')

  raise_last_win_32_error if writeFile.call(hFile, buffer, buffer.size,
    written, 0).zero?

  written.unpack('I')
end

def read_file(hFile)
  params = [
    'L', # handle of file to read
    'P', # pointer to buffer that receives data
    'L', # number of bytes to read
    'P', # pointer to number of bytes read
    'L'] #pointer to structure for data

  number = [0].pack('I')
  buffer = ' ' * 255

  readFile = Win32API.new("kernel32", "ReadFile", params, 'I')

  return '' if readFile.call(hFile, buffer, 255, number, 0).zero?

  buffer[0...number.unpack('I')[0]]
end

if $0 == __FILE__
  require 'fox12'

  include Fox

  application = FXApp.new("popen", "popen")

  main = FXMainWindow.new(application, "popen", nil, nil, DECOR_ALL,
    0, 0, 500, 500, 10, 10, 10, 10, 10, 10)

  button = FXButton.new(main, "&Do it!", nil, nil, 0,
    FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT,
    0, 0, 0, 0, 10, 10, 5, 5)

  frame = FXHorizontalFrame.new(main,
    FRAME_THICK|FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

  edit = FXText.new(frame, nil, 0,
    LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_READONLY, 0, 0, 0, 0)

  edit.textColor, edit.backColor = 0xFFFFFF, 0

  button.connect(SEL_COMMAND) do
    cmd = 'cmd.exe'
    input = "dir\nexit\n"
    #input = "dir\n"

    # create 3 pipes
    child_in_r, child_in_w = create_pipe
    child_out_r, child_out_w = create_pipe
    child_error_r, child_error_w = create_pipe

    # Ensure the write handle to the pipe for STDIN is not inherited.
    set_handle_information(child_in_w, HANDLE_FLAG_INHERIT, 0)
    set_handle_information(child_out_r, HANDLE_FLAG_INHERIT, 0)
    set_handle_information(child_error_r, HANDLE_FLAG_INHERIT, 0)

    processId, threadId = create_process(cmd, child_in_r,
      child_out_w, child_error_w)

    # we have to close the handles, so the pipes terminate with the process
    close_handle(child_out_w)
    close_handle(child_error_w)

    write_file(child_in_w, input)

    while !(buffer = read_file(child_out_r)).empty?
      edit.appendText(buffer.gsub("\r", ''))
    end
  end

  application.create()
  main.show(PLACEMENT_SCREEN)
  application.run()
end 