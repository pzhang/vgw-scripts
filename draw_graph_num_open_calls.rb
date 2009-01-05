require 'time'
require 'gnuplot'
require 'vgw_database'
starttime = Time.parse(ARGV[0]) if ARGV[0]
starttime ||= (Time.now - 86400)
endtime = Time.parse(ARGV[1]) if ARGV[1]
endtime ||= (Time.now)
num_outstanding = 0
calls = []
samples = CallsData.find(:all, :conditions => ["time BETWEEN ? AND ? AND event IN (?)",
                                               starttime,endtime,["close", "open", "dialed"]],
                                               :order => "time ASC")
samples.each do |s|
  if s.event == "close"
    num_outstanding -= 1
  else
    num_outstanding += 1
  end
  calls << num_outstanding
end
Gnuplot.open do |gp|
#File.open("gnuplot.dat", "w") do |gp|
  #collect samples into vectors

  Gnuplot::Plot.new(gp) do |plot|
    #plot.term "png"
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

