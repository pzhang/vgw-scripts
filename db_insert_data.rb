#! usr/bin/ruby
require 'time'
require 'rubygems'
#gem 'gnuplot'
require 'lib/moving_avg'
require 'lib/call_data'
require 'active_config'

#requires calls_data.yml configuration file
#one line of config

config = ActiveConfig.new(:path => "config/")
DIRECTORY =  config.import_data.directory || "logs"
SEARCH_TERM = config.import_data.search_term || "**/vgw00*"
PARSE_REGEXES = config.import_data.parse_regexes || []
#Parse the data from stdin
last_zap = {}
updates = []
Dir.chdir(DIRECTORY)
files = Dir.glob(SEARCH_TERM)
puts "files to be retrieved: "
puts files.inspect
files.each do |f|
 
  puts "got #{f.inspect}"
  updates = []
  fields = Set.new
  last_dialed = {}
  readfile = File.new(f, "r")
    while readfile.gets
      #REGEXES to parse events out of logs.
      line = {}
      case $_
        when /CHANUNAVAIL.*Busy\("SIP\/10.224.24.145-(.{8})/   
          line[:event] = 'CHANUNAVAIL'
          line[:channel] = last_zap[$1]
          fields << :event << :channel
        when /CHANUNAVAIL.*NoOp\("SIP\/10.224.24.145-(.{8}).*"([A-Z]* HUC: (\d*))"/ 
          line[:event] = $2
          line[:number] = last_dialed[$1]
          line[:code] = $3
          fields << :event << :number << :code
        when /Dial\("SIP\/10.224.24.145-(.{8})", "Zap\/[^\/]*\/(\d*)/
          line[:event] = 'DIALED'
          event = 'DIALED'
          fields << :event
          last_dialed[$1] = $2
        when /Zap\/(\d{1,2})-\d{1,2} is proceeding passing it to SIP\/10.224.24.145-(.{8})/
          last_zap[$2] = $1
        when /answered SIP\/10.224.24.145-(.{8})/
          line[:event] = 'answered'
          line[:number] = last_dialed[$1]
          fields << :event << :number
      end
      PARSE_REGEXES.each do |pg|
        if $_.match(/#{pg['regex']}/)
          (pg['static_data'] || {}).each_pair do |k, v|
            fields << k.to_sym
            line[k.to_sym] ||= v
          end
          (pg['dynamic_data'] || {}).each_pair do |k, v|
            fields << k.to_sym
            line[k.to_sym] ||= $~[v.to_i]
          end
        end
      end

      unless line.empty?
        date_str = $_.match(/^\[([^\]]+)\]/)[1]
        time = Time.parse(date_str)
        time -= 365*24*60*60 if time > Time.now
        line[:source] = f.split("/").last
        line[:time] = time
        fields << :source << :time
        updates << line
      end
    end
    updates.map! do |u| 
      fields.map do |f| 
        u[f] ? u[f].to_s.downcase : nil
      end
    end
    puts "importing #{updates.size} entries"
    puts CallData.import fields.to_a, updates, :validate => false unless updates.empty?
end
