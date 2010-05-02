require 'win32/registry'
#reg.each_value { |name, type, data| ... }        # Enumerate values


class ComExplorer
  
  attr_reader :list
  
  def initialize
    hkey = Win32::Registry::HKEY_CLASSES_ROOT
    base = 'CLSID'
    @list = []
    # open CLSID
    hkey.open(base) do |reg1|
      reg1.each_key { |key1, wtime|
        # open key
        hkey.open(base+'\\'+key1) do |reg2|
          # search ProgID
          reg2.each_key { |key2, wtime|
            if key2.upcase=='PROGID' # TODO: use also VERSIONINDEPENDENTPROGID
              # open first value
              hkey.open(base+'\\'+key1+'\\'+key2) do |reg3|
                #puts reg
                begin
                  @list << [reg3[0],base+'\\'+key1] # if reg3[0] =~ /Parser/
                  # TODO: add typelib
                rescue
                  puts "can not read #{reg3.inspect}"
                end
              end
            end
          }
        end
      }
    end
    @list.sort!
  end
  
end