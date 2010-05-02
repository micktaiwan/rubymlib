require 'win32ole'

class MExcelCompare
  attr_accessor :file1, :file2, :sheet, :limit

  def initialize
    @file1 = ""
    @file2 = ""
    @sheet = 1
    @limit = 500
  end
	
  def compare
    puts "file1:#@file1"
    puts "file2:#@file2"
    puts
		
    begin
      excel = WIN32OLE::new('excel.Application')
      wb1 = excel.Workbooks.Open(@file1)
      ws1 = wb1.Worksheets(@sheet)
      wb2 = excel.Workbooks.Open(@file2)
      ws2 = wb2.Worksheets(@sheet)
      ob = excel.workbooks.add
      os = ob.Worksheets(1)
      line = 1
      begin
        l1 = ws1.Range("a#{line}:z#{line}").value
        l2 = ws2.Range("a#{line}:z#{line}").value
        os.Range("a#{line}:z#{line}").value = l2
        Out(l1,l2,os,line) if l1 != l2
        line += 1
      end while line < @limit
    rescue Exception => e
      puts 'An error occurred while trying to process the Excel files'
      puts e
    rescue
      puts 'Error occured, don\'t know what'
    ensure
      wb1.Close(1)
      wb2.Close(1)
      ob.saveas('c:\ExcelCompareOut.xls')
      #ob.Close(1)
      #worksheet.Select
      excel['Visible'] = true
      #excel.Quit
      #excel = nil
      #GC.start
    end
		
  end
	
  def Out(l1,l2,os,line)
    # color the cell
    i = 0
    while i < l1[0].size
      if l1[0][i] != l2[0][i]
        letter = (97+i).chr
        os.Range("#{letter}#{line}").Interior['ColorIndex'] = 36
      end
      i += 1
    end

  end
	

end
