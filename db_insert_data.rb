require 'time'
require 'rubygems'
#gem 'gnuplot'
require 'lib/moving_avg'
require 'lib/call_data'
require 'active_config'

#requires calls_data.yml configuration file
#one line of config

config = ActiveConfig.new(:path => "config/")
DIRECTORY = config.calls_data.directory ? config.calls_data.directory : "."
SEARCH_TERM = config.calls_data.search_term ? config.calls_data.search_term : "**/vgw00*"
#Parse the data from stdin
samples = []
last_zap = {}
updates = []
noop_types = []
Dir.chdir(DIRECTORY)
files = Dir.glob(SEARCH_TERM)
puts "files to be retrieved: "
puts files.inspect
files.each do |f|
 
  puts "got #{f.inspect}"
  updates = []
  last_dialed = {}
  readfile = File.new(f, "r")
    while readfile.gets
      #REGEXES to parse events out of logs.
      event = nil
      case $_
        #when /CHANUNAVAIL.*Busy/                     : :chan_unavail
        when /CHANUNAVAIL.*Busy\("SIP\/10.224.24.145-(.{8})/   
          event = :CHANUNAVAIL
          channel = last_zap[$1]
        when /CHANUNAVAIL.*NoOp\("SIP\/10.224.24.145-(.{8}).*"([A-Z]* HUC: \d*)"/ 
          event = $2
          noop_types << event
          num = last_dialed[$1]
          code = event.match(/\d+/)[0]
        when /CONGESTION.*Busy/                     
          event = :congestion
        when /Busy\(/                               
          event =  :busy
        when /Dial\("SIP\/10.224.24.145-(.{8})", "Zap\/[^\/]*\/(\d*)/
          event = :DIALED
          last_dialed[$1] = $2
        when /Dial\("SIP\//
          event = :DIALED
        when /Zap\/(\d{1,2})-\d{1,2} is proceeding passing it to SIP\/10.224.24.145-(.{8})/
          last_zap[$2] = $1
          nil
        when /Hungup 'Zap\//             
          event = :close
        when /Accepting call from/            
          event = :open
        when /answered SIP\/10.224.24.145-(.{8})/
          event = :answered
          num = last_dialed[$1]          
      end
  
      if event
        date_str = $_.match(/^\[([^\]]+)\]/)[1]
        channel = nil unless event == :CHANUNAVAIL
        num = nil unless (event == :answered || noop_types.include?(event))
        date = Time.parse(date_str)
        date -= 365*24*60*60 if date > Time.now
        updates << [date, event.to_s.downcase, channel, code, num,f.split("/").last]
      end
    end
    fields = [:time, :event, :channel,:code, :number,:source]
    puts "importing #{updates.size} entries"
    puts CallsData.import fields, updates, :validate => false unless updates.empty?
end
