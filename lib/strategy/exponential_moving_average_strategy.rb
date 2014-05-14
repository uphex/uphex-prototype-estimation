require "uphex-estimation"
require 'strategy/exponential_moving_average_context'

module UpHex
  module Prediction
    class ExponentialMovingAverageStrategy < Strategy
    
      def initialize(ts)
        super(ts)

        raise ArgumentError.new("Invalid data set length") if @timeseries.length  < 2
      end

      def merge_default_options(opts)
        model = {:period_count => 365.0, :interval_ratio => 5.0}.merge((opts[:model] || {}))
        {:model => model, :range => (0..@timeseries.length)}.merge(opts)
      end
    
      
      def perform_prediction(context, date, value )
        
        # create a new prediction container for the next date,value pair
        current_prediction = Prediction.new(date, value)
        
        current_prediction.predicted_value = context.alpha*current_prediction.actual_value + (1.0-context.alpha) * context.last_prediction.predicted_value
        residual = (current_prediction.predicted_value - current_prediction.actual_value).abs
        
        # i dislike recalculating the mean residual every time through the loop, but keeping a running_mean 
        # accumulates rounding errors very quickly
        context.residuals << residual        
        mean_residual = context.residual_mean

        # calculate the low and high range for outliers
        current_prediction.low_range = current_prediction.predicted_value - context.interval_ratio * mean_residual
        current_prediction.high_range = current_prediction.predicted_value + context.interval_ratio * mean_residual                 

        # set the outlier flag based on the range values
        current_prediction.outlier = (current_prediction.predicted_value < current_prediction.low_range || 
                                      current_prediction.predicted_value > current_prediction.high_range)
        
        return current_prediction
      end
      
      def forecast(foreward, opts = {})
        opts = merge_default_options(opts)

        foreward = foreward.to_i
        
        period_count = opts[:model][:period_count].to_f
        range = opts[:range]
        interval_ratio = opts[:model][:interval_ratio].to_f

        alpha = 2.0/(period_count+1.0)
      
        # subset based on the provided range. defaults to the full range of data
        # Ruby is copy-on-write so if we dont change anything inside subset[] then we aren't duplicating the
        # entire timeseries
        subset = @timeseries[range]
        
        # initial prediction
        initial_prediction = Prediction.new(subset[0][:date], subset[0][:value])
        
        context = ExponentialMovingAverageContext.new(alpha, interval_ratio, initial_prediction)
        
        # the actual forecasts
        forecasts = []

        # perform EMA for the existing data
        1.upto(subset.length-1) do |index|
          #  produce the next Prediction
          current = perform_prediction(context, subset[index][:date],subset[index][:value])
          # replace the last_prediction with the current
          context.last_prediction = current
        end
        
        # run ahead foreward periods
        1.upto(foreward) do |index|
          next_date = @timeseries.timespan.advance(context.last_prediction.date.to_time)
          current = perform_prediction(context, next_date, context.last_prediction.predicted_value)
          forecasts << current.dup
          context.last_prediction = current
        end
        
        # map the forecasts to the hashed form
        forecasts.map {|p| {:date => p.date.to_date, :forecast => p.predicted_value, :low => p.low_range, :high => p.high_range}}
        
      end
    
      def comparison_forecast(foreward, opts = {})
        opts = merge_default_options(opts)

        foreward = foreward.to_i

        period_count = opts[:model][:period_count].to_f
        range = opts[:range]
        interval_ratio = opts[:model][:interval_ratio].to_f

        alpha = 2.0/(period_count+1.0)
  
        # initial prediction
        initial_prediction = Prediction.new(@timeseries[range.begin][:date], @timeseries[range.begin][:value])
        context = ExponentialMovingAverageContext.new(alpha, interval_ratio, initial_prediction)
        
        # bump the range forward one as we've already used the first point in the initial prediction
        foreward_range = Range.new(range.min+1,range.max)
        
        # perform EMA on the specified range
        @timeseries[foreward_range].each do |item|
          current = perform_prediction(context, item[:date],item[:value])
          context.last_prediction = current
        end
                                
        remaining_range = Range.new(foreward_range.max+1, @timeseries.length)
        forecasts = []
        # perform EMA on the remainging dataset, stepping ``foreward`` points at a time
        remaining_range.step(foreward).each do |base_index|
          0.upto(foreward-1).each do |inner_index|
            offset = base_index + inner_index
            
            break if offset >= @timeseries.length
            
            item = @timeseries[offset]
            
            current = perform_prediction(context, item[:date],item[:value])
            forecasts << current.dup
            context.last_prediction = current            
          end
        end
        
        # perform EMA ahead ``foreward`` -number of periods, using the predicted values as the actual values
        0.upto(foreward-1).each do |index|
          next_date = @timeseries.timespan.advance(context.last_prediction.date.to_time)
          current = perform_prediction(context, next_date, context.last_prediction.predicted_value)
          forecasts << current.dup
          context.last_prediction = current
        end
        forecasts.map {|p| {:date => p.date.to_date, :forecast => p.predicted_value, :low => p.low_range, :high => p.high_range}}
        
      end
    end
  end
end
