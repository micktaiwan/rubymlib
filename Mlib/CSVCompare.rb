require 'FasterCSV'


def read_csv(filename)
    return FasterCSV::Table.new( FasterCSV.read(filename) ).by_col
end

data1 = read_csv("test/data1.csv")
data2 = read_csv("test/data2.csv")

compare_column_idx = 1
unless data1[compare_column_idx] == data2[compare_column_idx]
    puts "column #{compare_column_idx} is different"
end 
