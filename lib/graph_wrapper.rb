require 'rubygems'
require 'gnuplot'
require 'active_config'

class GraphWrapper
attr_accessor :config_file, :config_path
def initialize(path, file = nil)
  @config_path = path
  @config_file = file
end
  
def plot(data, destination = nil)
  return unless data
  config = ActiveConfig.new(:path => config_path).send(config_file.to_sym).graph.to_hash
  Gnuplot.open do |gp|
    Gnuplot::Plot.new(gp) do |plot|
      config["plot"].each_pair do |k, v|
        puts "#{k} : #{v}"
        eval("plot.#{k}(v)")
      end
      if data.class == Array
        plot.data << Gnuplot::DataSet.new( data ) do |ds|
          config["data_set"].each_pair do |k,v|
            ds.send("#{k.to_sym}=", v) 
          end
        end
      elsif data.class == Hash
        data.each_pair do |k, v|
          plot.data << Gnuplot::DataSet.new( v ) do |ds|
            ds.title = k
            config["data_set"].each_pair do |k2,v2|
              ds.send("#{k2.to_sym}=",v2)
            end
          end #Gnuplot dataset do
        end #data.each_pair
      end #if statement
      plot.output destination
    end #gnuplot.plot
  end #gnuplot open

end

end
