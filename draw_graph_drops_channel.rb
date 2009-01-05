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
drops = CallsData.find(:all, :conditions => ["time BETWEEN ? AND ? AND channel >= ?", starttime,endtime, 0],:order => "channel ASC")
samples = []
drops.each do |d|
  if d.channel
    samples[d.channel.to_i] ||= 0
    samples[d.channel.to_i] += 1
  end
end

Gnuplot.open do |gp|
#File.open("gnuplot.dat", "w") do |gp|
  #collect samples into vectors

  samples.collect! {|s| s.to_f}
  puts samples.inspect
	Gnuplot::Plot.new(gp) do |plot|
    plot.term  "png"
    plot.data << Gnuplot::DataSet.new( samples ) do |ds|
      ds.title = "drops per channel"
      ds.using = "1"
      ds.with = "boxes fs solid"
    end
  plot.output "dropped_calls_by_channel-#{starttime.strftime("%m-%d-%Y-%H:%M")}-#{endtime.strftime("%m-%d-%Y-%H:%M")}.png"
  end

end

