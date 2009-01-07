require 'time'
require 'gnuplot'
require 'call_data'
starttime = Time.parse(ARGV[0]) if ARGV[0]
starttime ||= (Time.now - 86400)
endtime = Time.parse(ARGV[1]) if ARGV[1]
endtime ||= (Time.now)
num_outstanding = 0
calls = []
source = ARGV[2] ? ARGV[2] : "all"
find_conditions = ["time BETWEEN ? AND ? AND event IN (?)",
                   starttime,endtime,["close", "open", "dialed"]]
if source && !source == "all"
    find_conditions[0] += " AND source = ?"
    find_conditions << source
end

samples = CallData.find(:all, :conditions => find_conditions,
                                               :order => "time ASC")
samples.each do |s|
  if s.event == "close"
    num_outstanding -= 1
  else
    num_outstanding += 1
  end
  calls << num_outstanding
end
unless samples.empty?
Gnuplot.open do |gp|

  Gnuplot::Plot.new(gp) do |plot|
      plot.term "png"
      plot.xdata "time"
      plot.timefmt "\"%m/%d-%H:%M:%S\""
      plot.format "x \"%m/%d %H:%M\""
      plot.xtics "rotate by 90"
      plot.ylabel "\"Open Calls\""

      plot.data << Gnuplot::DataSet.new( [samples.collect {|s| s.time.strftime("%m/%d-%H:%M:%S")}, calls] ) do |ds|
        ds.title = "Num Used Channels"
        ds.using = "1:2"
        ds.with = "lines"
      end

    end

  end
end

