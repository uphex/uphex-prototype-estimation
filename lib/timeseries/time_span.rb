module UpHex
  module Prediction
    class TimeSpan
      SECONDS_IN_MINUTE = 60.0
      SECONDS_IN_HOUR = SECONDS_IN_MINUTE * 60.0
      SECONDS_IN_DAY = SECONDS_IN_HOUR * 24.0
      SECONDS_IN_WEEK = SECONDS_IN_DAY * 7.0

      attr_accessor :span

      def self.from_seconds(seconds)
        TimeSpan.new(seconds)
      end

      def self.from_minutes(minutes)
        TimeSpan.new(minutes*SECONDS_IN_MINUTE)
      end

      def self.from_hours(hours)
        TimeSpan.new(hours*SECONDS_IN_HOUR)
      end

      def self.from_days(days)
        TimeSpan.new(days*SECONDS_IN_DAY)
      end

      def self.from_weeks(weeks)
        TimeSpan.new(weeks*SECONDS_IN_WEEK)
      end

      def self.from_times(t0,t1)
        throw ArgumentError.new("Argument was not a time") unless t0.is_a?(Time) && t1.is_a?(Time)

        diff = (t1-t0)
        self.from_seconds(diff)
      end

      def self.from_hash(h)
        period = h.keys[0]
        value = h[period]

        send("from_#{period.to_sym}", value)
      end

      def advance(t0)
        throw ArgumentError.new("Argument was not a time") unless t0.is_a?(Time)
        t0 + self.span
      end

      private

      def initialize(seconds)
        throw ArgumentError.new("Invalid span type") unless [Float,Fixnum,String].include?(seconds.class) == true
        @span = seconds.to_f.round(0).abs
      end
    end
  end
end
