require 'rubygems'
require 'moving_avg'
require 'vgw_database'
require 'gnuplot'
require 'time'
require 'set'
require 'active_config'

config = ActiveConfig.new(:path => ".")
if config.call_avg_number
  sample_interval = config.call_avg_number.sample_interval
  window_size = config.call_avg_number.window_size
  smoothing_factor = config.call_avg_number.smoothing_factor 
end
sample_interval ||= 30
window_size ||= 300
smoothing_factor ||= 0.1
starttime = ARGV[0] ? Time.parse(ARGV[0]) : (Time.now - 86400)
endtime = ARGV[1] ? Time.parse(ARGV[1]) : (Time.now)
source = ARGV[2] ? ARGV[2] : "all"

Gnuplot.open do |gp|
  events = config.call_avg_number.events
  find_conditions = ["time BETWEEN ? AND ? ", starttime, endtime] 
 
  if events && !events.empty?
    find_conditions[0] += "AND event IN(?) "
    find_conditions << events
  end
  if source && source != "all"
    find_conditions[0] += " AND source = ?"
    find_conditions << source
  end
  points = CallsData.find(:all, :conditions => find_conditions, :order => "time ASC")
  event_types = Set.new
  points.each {|s| event_types << s.event}
 
  if !event_types.empty?
    ma = MovingAverage.new(sample_interval, window_size, smoothing_factor)
    samples = []
    Gnuplot::Plot.new(gp) do |plot|
      plot.term "png"
      plot.xdata "time"
      plot.timefmt "\"%m/%d-%H:%M:%S\""
      plot.format "x \"%m/%d %H:%M\""
      plot.xtics "rotate by 90"
      plot.ylabel "\"Calls / Second\""
      plot.ytics "nomirror"
      points.each do |p|
        ma.add_event(p.time, p.event) do |sample|
          samples << sample
        end
      end
      x = samples.collect { |s| s[:time].strftime("%m/%d-%H:%M:%S") }
      event_types.each do |type|
        plot.data << Gnuplot::DataSet.new( [x,samples.collect { |s| s[type].to_f } ]) do |ds|
          ds.title = "#{type}"
          ds.using = "1:2"
          ds.with = "lines"
        end
      end
    end
  end
end
