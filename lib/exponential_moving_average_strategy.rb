require "uphex-estimation"

module UpHex
	module Prediction
	  class ExponentialMovingAverageStrategy < UpHex::Prediction::Strategy
    
	    def initialize(ts)
	      super(ts)
      
	      raise ArgumentError.new("Invalid data set length") if @timeseries.length  < 2
	    end

	    def merge_default_options(opts)
				{:period_count => 365.0, :range => (0..@timeseries.length), :interval_ratio => 3.0}.merge(opts)
	    end
    
			
			def next_prediction(last_prediction, residuals, current_prediction, alpha, interval_ratio)
				current_prediction.predicted_value = alpha*current_prediction.actual_value + (1.0-alpha) * last_prediction.predicted_value
        residual = (current_prediction.predicted_value - current_prediction.actual_value).abs
				
				# i dislike recalculating the mean residual every time through the loop, but keeping a running_mean 
        # accumulates rounding errors very quickly
        residuals << residual        
        mean_residual = residuals.inject(0.0) {|sum, r| sum + r} / residuals.size

				# calculate the low and high range for outliers
				current_prediction.low_range = current_prediction.predicted_value - interval_ratio * mean_residual
				current_prediction.high_range = current_prediction.predicted_value + interval_ratio * mean_residual                 

				current_prediction.outlier = (current_prediction.predicted_value < current_prediction.low_range || 
																			current_prediction.predicted_value > current_prediction.high_range)
				
			end
			
			def forecast(foreward, opts = {})
				opts = merge_default_options(opts)

				foreward = foreward.to_i
				
				period_count = opts[:period_count].to_f
				range = opts[:range]
				interval_ratio = opts[:interval_ratio]
				
	      results = []
      
	      alpha = 2.0/(period_count+1.0)
      
	      # extend subset range to include forecast count (foreward)
	      extended_range = Range.new(range.begin, range.end+foreward)
      
	      # subset based on the provided range plus the periods forward
	      # defaults to the full range of data
	      subset = @timeseries[extended_range]
				
				# since the EMA only uses the current and last values we can avoid duplicating the
				# entire subset in memory
				working = []
				
				# initial prediction
				last_prediction = Prediction.new(subset[0][:date], subset[0][:value])
				
				# the actual forecasts
				forecasts = []
				
				residuals = []
				
				1.upto(subset.length-1) do |index|
					current = Prediction.new(subset[index][:date], subset[index][:value])
								
					#	produce the next predicted value and the outlier range
					next_prediction(last_prediction, residuals, current, alpha, interval_ratio)
					
					# replace the last_prediction with the current
					last_prediction = current
					
					# put a copy of the current prediction into the forecasts container if we're past the end of the original range
					forecasts << current.dup if index > range.end
				end
				
				# map the forecasts to 
				forecasts.map {|p| {:date => p.date, :forecast => p.predicted_value, :low => p.low_range, :high => p.high_range}}
				
			end
    
	    def comparison_forecast(foreward, opts = {})
      	[]
	    end
	  end
  end
end