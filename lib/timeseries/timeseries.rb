require 'forwardable'
require 'timeseries/time_span'
require 'timeseries/time_series_validator'

module UpHex
  module Prediction
    class TimeSeries
      extend Forwardable

      attr_reader :interval
      attr_reader :timespan

      def initialize(source_array, opts={})
        raise ArgumentError.new('Invalid source_array') unless TimeSeriesValidator.new(source_array).valid? == true

        # merge in provided options from the defaults
        opts = {:days => 30} if opts.nil? || opts.keys.length == 0
        @interval = opts
        @timespan = TimeSpan.from_hash(@interval)
        # reject a span of 0.
        throw ArgumentError.new("Non-zero span is required") unless @timespan.span != 0.0

        # sorting ascending
        @backing_data = source_array.sort {|l,r| l[:date] <=> r[:date]}
      end

      def_delegators :@backing_data, :length, :each, :each_with_index, :[]

      def each_for_range(range, &block)
        @backing_data[range].each(&block)
      end

      def each_with_index_for_range(range, &block)
        @backing_data[range].each_with_index(&block)
      end
    end
  end
end
