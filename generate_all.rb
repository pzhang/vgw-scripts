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
(config.generate_all.graphs || {}).each_pair do |k, v|

  v[:time_frames].each do |r|
    if ARGV.length == 2
      start_time = ARGV[0] ? DateTime.parse(ARGV[0]) : nil
      end_time = ARGV[1] ? DateTime.parse(ARGV[1]) : nil
    elsif ARGV.length == 1
      end_time = ARGV[0] ? DateTime.parse(ARGV[0]) : nil
    end
    end_time ||= DateTime.now
    case r
      when "day"
        start_time ||= end_time - DateTime.now.day_fraction
      when "week"
        start_time ||= end_time - DateTime.now.wday
      when "month"
        start_time ||= end_time - DateTime.now.mday
    end
    done[r] ||= []
    start_time ||= DateTime.now
    filename = v[:filename] || k.to_s
    filename += "_#{start_time.strftime("%m_%d_%Y")}"+
                "_#{end_time.strftime("%m_%d_%Y")}.png"
    file_path = nil
    if config.generate_all.destination
      file_path = File.expand_path(config.generate_all.destination)
    end
    rel_path = "graphs"
    if v[:directory]
      if file_path
        rel_path = File.join(rel_path, v[:directory])
      end
    end
    File.makedirs(File.join(file_path, rel_path))
    rel_path = File.join(rel_path, filename)
    total_path = File.join(file_path, rel_path)
    source = v[:source]
    source ||= "all"
    unless done.values.flatten.include?(rel_path)
      data = DataHandler.new("config/", v[:config])
      grapher = GraphWrapper.new("config/", v[:config])
      data.get_data(start_time, end_time, source)
      samples = data.get_handled_data
      summary_data[rel_path] = data.get_summary_data
      puts "got data"
      grapher.plot(samples, total_path) unless samples.empty?
      done[r] << rel_path
    end
    done[r].uniq!
  end
end
puts done.inspect
gen = HTMLGenerator.new
gen.make_all_pages(config.generate_all.destination, summary_data, done)
