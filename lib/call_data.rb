require 'rubygems'
require 'activerecord'
require 'ar-extensions'
require 'active_config'

config = ActiveConfig.new(:path => ".")

if config.database
  adapter = config.database.adapter 
  database = config.database.database 
end
adapter ||= "postgresql"
database ||= "postgres"

ActiveRecord::Base.establish_connection(
  :adapter => adapter,
  :database => database
)

class CallData < ActiveRecord::Base
  set_table_name "calls_data"
end
