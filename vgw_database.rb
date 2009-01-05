require 'rubygems'
require 'activerecord'
require 'ar-extensions'
ActiveRecord::Base.establish_connection(
  :adapter => "postgresql",
  :database => "postgres"
)

class CallsData < ActiveRecord::Base
  set_table_name "calls_data"
end
