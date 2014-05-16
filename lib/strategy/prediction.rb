module UpHex
  module Prediction    
    class Prediction
      attr_accessor :low_range, :high_range, :predicted_value, :actual_value, :date, :outlier
      
      def initialize(date, value)
        @date = date
        @actual_value = value
        @low_range = value
        @high_range = value
        @predicted_value = value
        @outlier = false
      end
      
      def outlier?
        !(@low_range..@high_range).cover? @predicted_value
      end
    end
  end
end