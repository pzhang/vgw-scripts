
class MovingAverage


  def initialize(sample_interval = 30, window_len = 100, smoothing_factor = 0.1)
    @evs = {}
    @window_len = window_len
    @sample_interval = sample_interval
		@smoothing_factor = smoothing_factor
		@last_sample = {}
  end

  # Add an event and yield samples of each event rate up to the time 
  # of the event being added.
  # We assume events are added in chronological order
  def add_event(event, event_type = :value)
    raise "Event Type can't = :time" if event_type == :time

    #initialize sample time and event window
		@sample_time ||= event - (event.to_i % @sample_interval)
    @evs[event_type] ||= []

    #generate samples up to event time
		while (@sample_time < event)
      #intialize the sample
			sample = {:time => @sample_time}
			@evs.keys.each do |et|
				while (@evs[et].first && @evs[et].first < @sample_time - @window_len)
					@evs[et].shift
				end

				freq = @evs[et].size.to_f / @window_len.to_f
        last = @last_sample[et] || 0

        #apply exponential smoothing
        sample[et] = last + @smoothing_factor * (freq - last)
			end

      @last_sample = sample

			yield(@last_sample) if block_given?
			@sample_time += @sample_interval
		end
    @evs[event_type] << event
  end

  def event_types
    @evs.keys
  end

end


