module UpHex
  module Prediction
    class ExponentialMovingAverageContext
      attr_accessor :residuals, :last_prediction, :alpha, :interval_ratio

      def initialize(alpha, interval_ratio, initial_prediction)
        @residuals = []
        @alpha = alpha
        @last_prediction = initial_prediction
        @interval_ratio = interval_ratio
      end

      def residual_mean
        @residuals.inject(0.0) {|sum, r| sum + r} / @residuals.size
      end
    end
  end
end
