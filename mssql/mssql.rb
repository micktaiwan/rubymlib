# gem install activerecord-sqlserver-adapter --source=http://gems.rubyonrails.org

require 'rubygems'
#require 'activerecord-sqlserver-adapter'


require 'dbi'
oConn = DBI.connect('DBI:ADO:Provider=SQLOLEDB;Data Source=PHONE;User ID=test;password=test')
oConn.select_all('SELECT COUNT(*) from visits'){|row| puts row}

#SQLNCLI
