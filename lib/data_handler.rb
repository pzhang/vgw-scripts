require 'call_data'
require 'rubygems'
require 'active_config'
require 'moving_avg'

class DataHandler
  attr_accessor :config_path, :config_file, :x_data, :config
  attr_reader :data
  def initialize(path, file = nil)
      @config_path = path
      @config_file = file
      @config = ActiveConfig.new(:path => config_path).send(config_file.to_sym).data.to_hash
      @x_data = @config["x_data"]
  end
  def get_data(start_date, end_date, source = "all")
    statement = ["time BETWEEN :start_date AND :end_date",
                 {:start_date => start_date,:end_date => end_date}]
    unless source == "all"
      if source.class == Array
        statement[0] += " AND source IN(:source)"
      else
        statement[0] += " AND source = :source"
      end
    end
    statement[1][:source] = source
    if @config['statement']
      statement[0] += " AND #{@config['statement']}"
      bindings = {}
      @config['bindings'].each_pair {|k,v| bindings[k.to_sym] = v}
      statement[1].merge!(bindings)
    end 
    options = {:conditions => statement}
    options[:order] = @config['order'] if @config['order']
    @data = CallData.find(:all, options)
    return true if @data
    return false
  end
  
  def get_column(column_name)
    return @data.map {|d| d.send(column_name.to_sym)}
  end
  
  def get_handled_data
    handled_data = []
    if config['moving_average']
      handled_data = calculate_moving_average(config['moving_average'])
    elsif config['aggregate']
      handled_data = []
      split_data_by_uniq_vals(config['aggregate']).each do |s|
        handled_data[s[0].to_i] = s[1].size.to_f
      end
      handled_data.map! {|h| h.to_f}
    elsif config['custom_aggregate']
      handled_data = custom_aggregate
    end
    return handled_data
  end  
  def custom_aggregate
    custom_config = config['custom_aggregate']
    agg_data = {}
    x = data.map {|d| d.send((x_data || :time).to_sym).strftime("%m/%d-%H:%M:%S")}
    custom_config.each_pair do |k, v|
      counter = 0
      c_snap = []
      data.each do |d| 
        if v['increasing'].include?(d.send(k))
          counter += 1
        elsif v['decreasing'].include?(d.send(k))
          counter -= 1
        end
        c_snap << counter
      end
      agg_data[k] = [x, c_snap] unless [x,c_snap].flatten.empty?
    end    
    return agg_data
  end
  def split_data_by_uniq_vals(column_name)
    r_data = {}
    @data.each do |d|
      r_data[d.send(column_name)] ||= []
      r_data[d.send(column_name)] << d
    end
    return r_data
  end
  
  def calculate_moving_average(column_name)
    ma = MovingAverage.new
    moving_avg_data = []
    @data.each do |d|
      ma.add_event( d.send((x_data || :time).to_sym), d.send(column_name) ) do |s|
        moving_avg_data << s
      end
    end
    x = moving_avg_data.collect {|mv| mv[(x_data || :time).to_sym].strftime("%m/%d-%H:%M:%S")}
    r_data = {}
    ma.event_types.each do |e|
      r_data[e] = [x, moving_avg_data.collect {|m| m[e].to_f}]
    end
    return r_data
  end
end
