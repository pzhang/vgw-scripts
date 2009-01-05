require 'rubygems'
require 'moving_avg'
require 'vgw_database'
require 'gnuplot'
require 'time'
require 'set'

SAMPLE_INTERVAL = ARGV[2] ? ARGV[2].to_f : 30
WINDOW_SIZE = ARGV[3] ? ARGV[3].to_f : 5*60
SMOOTHING_FACTOR = ARGV[4] ? ARGV[4].to_f : 0.1

starttime = Time.parse(ARGV[0]) if ARGV[0]
starttime ||= (Time.now - 86400)
endtime = Time.parse(ARGV[1]) if ARGV[1]
endtime ||= (Time.now)
Gnuplot.open do |gp|
#File.open("gnuplot.dat", "w") do |gp|
  #collect samples into vectors
  ARGV.slice!(0,2)
  events = ARGV unless ARGV.empty?
  events ||= []
  find_conditions = {:time => starttime..endtime}
  find_conditions[:event] = events unless events.empty?
  points = CallsData.find(:all, :conditions => {:time => starttime..endtime}, :order => "time ASC")
  x = points.collect { |s| s.time.strftime("%m/%d-%H:%M:%S") }
 # percent_unavail = samples.collect { |s| 100 * s[:CHANUNAVAIL].to_f / s[:DIALED].to_f  }
  event_types = Set.new
  points.each {|s| event_types << s.event}
  if !event_types.empty?
    ma = MovingAverage.new(SAMPLE_INTERVAL, WINDOW_SIZE, SMOOTHING_FACTOR)
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
    puts "Event types incorrectly inputted"
  end
end
