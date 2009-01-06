require 'rubygems'
require 'moving_avg'
require 'vgw_database'
require 'gnuplot'
require 'time'
require 'set'

sample_interval = config.call_avg_number.sample_interval || SAMPLE_INTERVAL || 30
window_size = config.call_avg_number.window_size || WINDOW_SIZE || 5*60
smoothing_factor = config.call_avg_number.smoothing_factor || SMOOTHING_FACTOR || 0.1

starttime = START_TIME || (Time.now - 86400)
endtime = END_TIME || (Time.now)
Gnuplot.open do |gp|
#File.open("gnuplot.dat", "w") do |gp|
  #collect samples into vectors
  events = config.graphs.call_avg_number.events
  find_conditions = {:time => starttime..endtime}
  find_conditions[:event] = events unless events.empty?
  points = CallsData.find(:all, :conditions => find_conditions, :order => "time ASC")
  x = points.collect { |s| s.time.strftime("%m/%d-%H:%M:%S") }
 # percent_unavail = samples.collect { |s| 100 * s[:CHANUNAVAIL].to_f / s[:DIALED].to_f  }
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
      #plot.y2label "\"% Chanunavail\""
      plot.ylabel "\"Calls / Second\""
      plot.ytics "nomirror"
      #plot.y2tics 
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
          #ds.with = "boxes"
          ds.with = "lines"
        end
      end
      plot.output "calls_per_sec_by_events" + 
                  "-#{starttime.strftime("%m-%d-%Y-%H:%M")}-#{endtime.strftime("%m-%d-%Y-%H:%M")}.png"
    #plot.data << Gnuplot::DataSet.new( [x,percent_unavail] ) do |ds|
      #ds.title = "Percent Chanunavail"
      #ds.using = "1:2 axes x1y2"
      #ds.with = "lines"
    #end
    end
  else
    puts "Nothing to graph (event types incorrect or no data returned)"
  end
end
