require 'time'
require 'rubygems'
#gem 'gnuplot'
require 'gnuplot'
require 'moving_avg'
require 'vgw_database'

#Parse the data from stdin
starttime = Time.parse(ARGV[0]) if ARGV[0]
starttime ||= (Time.now - 86400)
endtime = Time.parse(ARGV[1]) if ARGV[1]
endtime ||= (Time.now)
source = ARGV[2] ? ARGV[2] : "all"
find_conditions = ["time BETWEEN ? AND ? AND channel >= ?", starttime,endtime, 0]
if source && !source == "all"
    find_conditions[0] += " AND source = ?"
    find_conditions << source
end

drops = CallsData.find(:all, :conditions => find_conditions,:order => "channel ASC")
samples = []
drops.each do |d|
  if d.channel
    samples[d.channel.to_i] ||= 0
    samples[d.channel.to_i] += 1
  end
end
unless samples.empty?
  Gnuplot.open do |gp|
#File.open("gnuplot.dat", "w") do |gp|
  #collect samples into vectors

    samples.collect! {|s| s.to_f}
   	Gnuplot::Plot.new(gp) do |plot|
      plot.term  "png"
      plot.data << Gnuplot::DataSet.new( samples ) do |ds|
        ds.title = "drops per channel"
        ds.using = "1"
        ds.with = "boxes fs solid"
      end
 #   plot.output "dropped_calls_by_channel-#{starttime.strftime("%m-%d-%Y-%H:%M")}-#{endtime.strftime("%m-%d-%Y-%H:%M")}.png"
    end

  end
end
