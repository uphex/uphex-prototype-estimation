module UpHex
  module Prediction
    class HoltWintersStrategy < Strategy
      
      def initialize(timeseries, additive_seasonal=true, frequency=1, period=365)
        super(timeseries)

        @additive_seasonal = additive_seasonal
        @frequency = frequency
        @period = period
        
      end

      def merge_default_options(opts)
        model = {:alpha => 0.1, :beta => 0.0 }.merge(opts[:model])
        opts[:model] = model
        {:range => (0..@timeseries.length), :confidence_level => 0.95}.merge(opts)
      end
      
      def comparison_forecast(foreward, opts = {})
        opts = merge_default_options(opts)

        range = opts[:range]
        
        confidence_level = opts[:confidence_level]
        
        model = opts[:model]
        
        alpha = model[:alpha]
        beta = model[:beta]
        
        ending_range = Range.new(range.max, @timeseries.length-1)
        
        forecasts = []
        
        time_span = @timeseries.timespan

        ending_range.step(foreward).each do |index|
          next_date = time_span.advance(@timeseries[range.max][:date].to_time)

          subset = @timeseries[Range.new(range.begin, index)]
          next_forecasts = holt_winters(subset, alpha, beta, confidence_level, foreward)

          forecasts += next_forecasts.map { |f| f[:date] = next_date.to_date; next_date = time_span.advance(next_date); f}

        end

        # we may have forecast past the end of our timeseries, so limit the forecasts to @timeseries.length        
        forecasts[Range.new(range.begin, @timeseries.length-range.max-1)]
      end
      
      def forecast(foreward, opts = {})

        opts = merge_default_options(opts)

        range = opts[:range]
        
        confidence_level = opts[:confidence_level]
        
        model = opts[:model]
        
        alpha = model[:alpha]
        beta = model[:beta]

        subset = @timeseries[range]
        
        time_span = @timeseries.timespan
        next_date = time_span.advance(@timeseries[range.max][:date].to_time)
        
        forecasts = holt_winters(subset, alpha, beta, confidence_level, foreward)
        
        forecasts.map { |f| f[:date] = next_date.to_date; next_date = time_span.advance(next_date); f}
      end
      
      # perform the initial calculations and the forecast + confidence intervals for ``foreward`` periods forward
      def holt_winters(subset, alpha, beta, confidence_level, foreward)

        level_start = 0
        trend_start = 0
        season_start = 0

        alpha = (alpha == false || !!alpha == false || alpha == 0.0) ? 0.0: alpha
        beta = (beta == false || !!beta == false || beta == 0.0) ? 0.0 : beta

        gamma = 0.0

        do_trend = (beta > 0.0)
        do_seasonal = (gamma > 0.0)

        exponential_smooth = !do_trend

        level_start = (exponential_smooth == false) ? subset[1][:value] : subset[0][:value]

        trend_start = (beta > 0.0) ? subset[1][:value] - subset[0][:value] : 0.0 

        # if we have a trend (beta) then start from offset 2, otherwise start from offset 1
        start_time = 2- ((exponential_smooth == false)? 0: 1)

        len = subset.length - start_time + 1

        # calculate hw forecast, gamma is always 0.0, seasonal_start is always 0.0
        level, trend, season,sum_squared_errors = hw_foreward(subset, alpha, beta, 0.0, level_start, 0.0, start_time)


        # final_level = level.pop
        # final_trend = trend.pop
        # final_season = season.pop
        # 
        # coefficients = [final_level, final_trend, final_season]
        coefficients = [level[-1], trend[-1], season[-1]]
        fit = Array.new(foreward, coefficients[0])
        

        fit = fit.map { |f| f * coefficients[1]} if (do_trend)
        
        # ignore season[] coefficients for now
        
        # calculate the confidence intervals 
        intervals = 1.upto(foreward).collect {|i| Math.sqrt(vars(subset, i, alpha, beta, gamma, level))}
                               .map     {|j| j*UpHex::Prediction::Utility.cdf_inverse((1.0 + confidence_level) / 2)}

        # forecast
        forecasts = []
        foreward.times do |i| 
          forecasts << {:forecast => fit[i], :high => fit[i] + intervals[i], :low => fit[i] - intervals[i] }
        end

        forecasts

      end
      
      #### support functions for confidence interval calculations
      # original R code - 
      # object$alpha * (1 + j * object$beta) +
      #             (j %% f == 0) * object$gamma * (1 - object$alpha)
      def psi(j, alpha, beta, gamma)
        seasonal_scale = (j % @frequency == 0) ? 1 : 0
        alpha * (1+j*beta) + seasonal_scale * gamma * (1-alpha)
      end

      # original R code-
      # f <- frequency(object$x)
      # vars <- function(h) {
      #     psi <- function(j)
      #         object$alpha * (1 + j * object$beta) +
      #             (j %% f == 0) * object$gamma * (1 - object$alpha)
      #     var(residuals(object)) * if (object$seasonal == "additive")
      #         sum(1, (h > 1) * sapply(1L:(h-1), function(j) crossprod(psi(j))))
      #     else {
      #         rel <- 1 + (h - 1) %% f
      #         sum(sapply(0:(h-1), function(j) crossprod (psi(j) * object$coefficients[2 + rel] / object$coefficients[2 + (rel - j) %% f])))
      #     }
      # }
      def vars(subset, h, alpha, beta, gamma, level)
        # residuals
        # we need to ignore the first projection and truth value since the HW start time is always after 1
        # R handles these lists-of-different-sizes silently in residuals.HoltWinters function
        residuals = subset[1..-1].each_with_index.map { |value, i| value[:value] - level[i]}

        var = Utility.sample_variance(residuals)

        if @additive_seasonal 
          products = 1.upto(h-1).collect { |i| psi(i, alpha, beta, gamma) ** 2 }
          v = var * products.inject(1.0) { |sum, value| sum + value}
        else
          # multiplicitave seasonality TBD later
          v = 1
        end

        v
      end

      #### function to estimate the level and trend from existing data. 
      # R function signature
      # original C code inline
      # as.double(x),
      #            lenx,
      #            as.double(max(min(alpha, 1), 0)),
      #            as.double(max(min(beta, 1), 0)),
      #            as.double(max(min(gamma, 1), 0)),
      #            as.integer(start.time),
      #            ## no idea why this is so: same as seasonal != "multiplicative"
      #            as.integer(! + (seasonal == "multiplicative")),
      #            as.integer(f),
      #            as.integer(!is.logical(beta) || beta),
      #            as.integer(!is.logical(gamma) || gamma),
      # 
      #            a = as.double(l.start),
      #            b = as.double(b.start),
      #            s = as.double(s.start),
      # 
      #      ## return values
      #            SSE = as.double(0),
      #            level = double(len + 1L),
      #            trend = double(len + 1L),
      #            seasonal = double(len + f)
      #            )

      def hw_foreward(subset, alpha, beta, gamma, level_start, seasonal_start, start_time)
        res = 0.0
        xhat = 0.0
        stmp = 0.0


        i0=0
        s0=0

        level = []
        trend = []
        season = []

        level << level_start
        do_trend = (beta > 0.0)
        do_seasonal = (gamma > 0.0)

        if do_trend
          trend << trend_start 
        else
          trend = Array.new(subset.length+1,0.0)
        end

        if do_seasonal
          season = Array.new(@period, seasonal_start) if do_seasonal
        else
          season = Array.new(@period, 0.0)
        end

        sum_squared_errors = 0.0

        start_time.upto(subset.length - 1) do |i|

          # indicies in period i
          i0 = i - start_time + 1
          s0 = i0 + @period - 1

          # /* forecast *for* period i */
          #   xhat = level[i0 - 1] + (*dotrend == 1 ? trend[i0 - 1] : 0);
          #   stmp = *doseasonal == 1 ? season[s0 - *period] : (*seasonal != 1);
          #   if (*seasonal == 1)
          #       xhat += stmp;
          #   else
          #       xhat *= stmp;
          # 
          xhat = level[i0-1]
          xhat += (do_trend == false)? 0.0: trend[i0-1] 
          stmp = (do_seasonal == true) ? season[s0-@period] : 0.0

          if(@additive_seasonal)
            xhat += stmp
          else
            xhat *= stmp
          end

          # /* Sum of Squared Errors */
          #           res   = x[i] - xhat;
          #           *SSE += res * res;
          #       
          res = subset[i][:value] - xhat
          sum_squared_errors += (res * res)

          # /* estimate of level *in* period i */
          #   if (*seasonal == 1)
          #       level[i0] = *alpha       * (x[i] - stmp)
          #           + (1 - *alpha) * (level[i0 - 1] + trend[i0 - 1]);
          #   else
          #       level[i0] = *alpha       * (x[i] / stmp)
          #           + (1 - *alpha) * (level[i0 - 1] + trend[i0 - 1]);
          if @additive_seasonal == true
            level[i0] = alpha * (subset[i][:value] - stmp) + (1-alpha) * (level[i0-1] + trend[i0-1])
          else
            level[i0] = alpha * (subset[i][:value] / stmp) + (1-alpha) * (level[i0-1] + trend[i0-1])
          end

          # /* estimate of trend *in* period i */
          #   if (*dotrend == 1)
          #       trend[i0] = *beta        * (level[i0] - level[i0 - 1])
          #           + (1 - *beta)  * trend[i0 - 1];
          trend[i0] = beta * (level[i0] - level[i0-1]) + (1-beta) * trend[i0-1] if do_trend

          #         /* estimate of seasonal component *in* period i */
          # if (*doseasonal == 1) {
          #     if (*seasonal == 1)
          #   season[s0] = *gamma       * (x[i] - level[i0])
          #        + (1 - *gamma) * stmp;
          #     else
          #   season[s0] = *gamma       * (x[i] / level[i0])
          #        + (1 - *gamma) * stmp;
          # }        

          if do_seasonal
            if @additive_seasonal
              season[s0] = gamma * (subset[i] - level[i0]) + (1-gamma) * stmp
            else
              season[s0] = gamma * (subset[i] / level[i0]) + (1-gamma) * stmp
            end
          end
        end

        return level, trend, season, sum_squared_errors

      end
 
      private :holt_winters, :hw_foreward, :psi, :vars
     
    end
  end
end