require 'rubygems'
require 'active_config'
require 'vgw_database'

config = ActiveConfig.new(:path => '.')

DIRECTORY = config.graphs.directory
START_TIME = config.graphs.start_time
END_TIME = config.graphs.end_time

config.graphs.graphs.each do |g|

require g[:script]

end
