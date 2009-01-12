require 'rubygems'
require 'activerecord'
require 'ar-extensions'
require 'active_config'
require 'ar-extensions/import/postgresql'

config = ActiveConfig.new(:path => "config")

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
  set_table_name "call_data"
end
