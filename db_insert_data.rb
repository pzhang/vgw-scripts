require 'time'
require 'rubygems'
#gem 'gnuplot'
require 'moving_avg'
require 'vgw_database'
require 'active_config'

#requires calls_data.yml configuration file
#one line of config

config = ActiveConfig.new(:path => ".")
DIRECTORY = config.calls_data.directory ? config.calls_data.directory : "."

#Parse the data from stdin
ma= MovingAverage.new(SAMPLE_INTERVAL, WINDOW_SIZE, SMOOTHING_FACTOR)
samples = []
last_zap = {}
updates = []
noop_types = []
Dir.chdir(DIRECTORY)
files = Dir.glob("**/vgw001*")
files.each do |f|
  last_dialed = {}
  readfile = File.new(f, "r")
    while readfile.gets
      #REGEXES to parse events out of logs.
      event = nil
      case $_
        #when /CHANUNAVAIL.*Busy/                     : :chan_unavail
        when /CHANUNAVAIL.*Busy\("SIP\/10.224.24.145-(.{8})/   
          event = :CHANUNAVAIL
          last = last_zap[$1]
        when /CHANUNAVAIL.*NoOp\("SIP\/10.224.24.145-(.{8}).*"([A-Z]* HUC: \d*)"/ 
          event = $2
          noop_types << event
          num = last_dialed[$1]
          code = event.match(/\d*/)
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
        last = nil unless event == :CHANUNAVAIL
        num = nil unless (event == :answered || noop_types.include?(event))
        date = Time.parse(date_str)
        date -= 365*24*60*60 if date > Time.now
        updates << [date, event.to_s.downcase, last, code, num,f]
      end
    end
end
fields = [:time, :event, :channel,:code, :number,:source]
puts CallsData.import fields, updates
puts "#{updates.size} + imported"
