$: << File.expand_path("lib")
require 'ftools'
require 'rubygems'
require 'active_config'
require 'time'
require 'date'
require 'graph_wrapper'
require 'data_handler'
require 'html_generator'

config = ActiveConfig.new(:path => 'config/')

summary_data = {}
done = {}
(config.graphs.graphs || {}).each_pair do |k, v|

  v[:time_frames].each do |r|
    start_time = ARGV[0] ? DateTime.parse(ARGV[0]) : nil
    end_time = ARGV[1] ? DateTime.parse(ARGV[1]) : nil
    case r
      when "day"
        start_time ||= DateTime.now - DateTime.now.day_fraction
      when "week"
        start_time ||= DateTime.now - DateTime.now.wday
      when "month"
        start_time ||= DateTime.now - DateTime.now.mday
    end
    start_time ||= DateTime.now
    end_time ||= DateTime.now 
    filename = v[:filename] || k.to_s
    filename += "_#{start_time.strftime("%m_%d_%Y")}"+
                "_#{end_time.strftime("%m_%d_%Y")}.png"
    file_path = nil
    if config.graphs.directory
      file_path = File.expand_path(config.graphs.directory)
    end
    file_path ||= File.expand_path(".")
    file_path = File.join(file_path, DateTime.now.strftime("%m_%d_%Y"))
    if v[:directory]
      if file_path
        file_path = File.join(file_path, v[:directory])
      end
    end
    File.makedirs(file_path)
    file_path = File.join(file_path, filename)
    source = v[:source]
    source ||= "all"
    unless done.values.flatten.include?(file_path)
      data = DataHandler.new("config/", v[:config])
      grapher = GraphWrapper.new("config/", v[:config])
      data.get_data(start_time, end_time, source)
      samples = data.get_handled_data
      summary_data[file_path] = data.get_summary_data
      puts "got data"
      grapher.plot(samples, file_path) unless samples.empty?
      done[r] << file_path
    end
    done[r].uniq!
  end
end
gen = HTMLGenerator.new("graphs")
gen.make_all_pages("pages", summary_data, done)
