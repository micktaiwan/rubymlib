require "MExcelCompare"

ec = MExcelCompare.new
ec.file1 = 'D:\tmp\SR-MV²_RM3_Wave2_RequirementsReferential_v2.4.xls'
ec.file2 = 'D:\tmp\SRMV2_RM3_Wave2_RequirementsReferential_v2.4.xls'
ec.sheet = 4
ec.limit = 140
ec.compare
