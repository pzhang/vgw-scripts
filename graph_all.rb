require 'ftools'
require 'rubygems'
require 'active_config'
require 'time'
config = ActiveConfig.new(:path => 'config/')

config.graphs.graphs.each_pair do |k, v|

  v[:time_frames].each do |r|
    case r
      when "day"
        start_time = Time.now - 60*60*24
      when "week"
        start_time = Time.now - 60*60*24*7
      when "month"
        start_time = (DateTime.now << 1)
    end
    start_time ||= Time.now
    start_time = start_time.strftime("%m/%d/%Y")
    end_time = Time.now.strftime("%m/%d/%Y")
    filename = v[:filename] || k.to_s
    filename += "_#{start_time.gsub("/", "-")}_#{end_time.gsub("/", "-")}.png"
    file_path = nil
    if config.graphs.directory
      file_path = File.expand_path(config.graphs.directory)
    end
    if v[:directory]
      if file_path
        file_path = File.join(file_path, v[:directory])
      else
        file_path = File.expand_path(v[:directory])
      end
    end
    file_path ||= "."
    File.makedirs(file_path)
    file_path = File.join(file_path, filename)
    source = nil
    if v[:source] && v[:source] != "all"
      source = v[:source]
    end  
    puts "generating #{filename}"
    system "cd lib && ruby #{v[:script]} #{start_time} #{end_time} #{source} > #{file_path}"
  end
end
