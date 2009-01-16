require 'call_data'
require 'rubygems'
require 'active_config'
require 'moving_avg'

class DataHandler
  attr_accessor :config_path, :config_file, :x_data, :config 
  attr_reader :data, :handled_data
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
    statement[1][:source] = source
    end
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
  def handled_data
    @handled_data ||= get_handled_data
    return @handled_data
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
    elsif config['delta_by_attr']
      handled_data = delta_by_attr
    end
    return handled_data
  end
  
  def get_summary_data
    return {} if data.empty?
    raw_d = handled_data
    sum_data = {}
    if handled_data.class == Hash
      handled_data.each_pair do |k, v|
        sorted_data = v[1].sort
        sum = 0
        sorted_data.each {|s| sum+=s}
        sum_data[k] = {'min' => sorted_data.first,
                       'max' => sorted_data.last,
                       'average' => (sum.to_f / sorted_data.size.to_f)}
        if config['summary']
          if config['summary']['sum'] == 'integration'
            sum_data[k]['sum'] = integrate(v)
          elsif config['summary']['sum'] != nil
            sum-data[k]['sum'] = sum
          end
        end     
      end    
    elsif handled_data.class == Array
      sum = 0
      sorted_data = handled_data.sort
      handled_data.each {|h| sum += h}
      sum_data["sum_data"] = {"average" => (sum.to_f / handled_data.size.to_f), 
                              "sum" => sum,
                              "max" => sorted_data.last}
    end
    return sum_data
  end
  def integrate(data_array = [])
    sum = 0
    i = 0
    while i < data_array[0].length - 1
      sum += (((data_array[1][i] + data_array[1][i+1]) / 2.0) * 
             (Time.parse(data_array[0][i+1]) - Time.parse(data_array[0][i])))
      i += 1
    end
    return sum
  end 

  def delta_by_attr
    custom_config = config['delta_by_attr']
    agg_data = {}
    x = data.map {|d| d.send((x_data || :time).to_sym).strftime("%m/%d/%Y-%H:%M:%S")}
    custom_config.each_pair do |k, v|
      counter = 0
      c_snap = []
      data.each do |d| 
        if v['increasing'].include?(d.send(k.to_sym))
          counter += 1
        elsif v['decreasing'].include?(d.send(k.to_sym))
          counter -= 1
        end
        c_snap << counter
      end
      agg_data[v['name'] || k] = [x, c_snap] unless [x,c_snap].flatten.empty?
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
    ma = MovingAverage.new(config['sample_interval'], config['window_size'],
                           config['smoothing_factor'])
    moving_avg_data = []
    data.each do |d|
      ma.add_event( d.send((x_data || :time).to_sym), d.send(column_name) ) do |s|
        moving_avg_data << s
      end
    end
    x = moving_avg_data.collect {|mv| mv[(x_data || :time).to_sym].strftime("%m/%d/%Y-%H:%M:%S")}
    r_data = {}
    ma.event_types.each do |e|
      r_data[e] = [x, moving_avg_data.collect {|m| m[e].to_f}]
    end
    return r_data
  end
end
