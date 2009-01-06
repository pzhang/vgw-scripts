require 'ftools'
require 'rubygems'
require 'active_config'
require 'time'
config = ActiveConfig.new(:path => '.')

config.graphs.graphs.each_pair do |k, v|

  v[:run_time].each do |r|
    case r
      when "day"
        start_time = Time.now - 60*60*24
      when "week"
        start_time = Time.now - 60*60*24*7
      when "month"
        start_time = (DateTime.now << 1)
      end
      start_time = start_time.strftime("%m/%d/%Y")
      end_time = Time.now.strftime("%m/%d/%Y")
    filename = v[:filename] || k.to_s
    filename += "_#{start_time.gsub("/", "-")}_#{end_time.gsub("/", "-")}.png"
    file_path = "."
    if config.graphs.directory
      file_path = File.expand_path(config.graphs.directory)
    end
    if v[:directory]
      file_path = File.join(file_path, v[:directory])  
    end
    File.makedirs(file_path)
    file_path = File.join(file_path, filename)
    source = nil
    if v[:source] && v[:source] != "all"
      source = v[:source]
    end  
    puts "generating #{filename}"
    system "ruby #{v[:script]} #{start_time} #{end_time} #{source} > #{file_path}"
  end
end
