require 'time_span'
require 'forwardable'

module UpHex
  module Prediction
    class TimeSeries
      extend Forwardable
      
      attr_reader :interval
      attr_reader :timespan
      
      def initialize(source_array, opts={})            
        # require the source array to be non-nil
        raise ArgumentError.new('Nil source array passed to TimeSeries') if source_array.nil?
      
        # require the source array to be an array
        raise ArgumentError.new('Invalid source passed to TimeSeries') unless source_array.is_a?(Array)  
      
        # require the source array to have a non-zero length
        raise ArgumentError.new('Empty source array passed to TimeSeries') if source_array.length == 0
      
        # validate the format of every entry of the source_array
      
        source_array.each_with_index do |item, index|
          # not a hash
          raise ArgumentError.new("Invalid source data type at index #{index}") unless item.is_a?(Hash)
        
          # missing :date        
          raise ArgumentError.new("Missing date attribute at index #{index}") unless item[:date].nil? == false
          # non-date :date
          raise ArgumentError.new("Invalid date attribute at index #{index}") unless item[:date].is_a?(Date)
         
          # missing :value       
          raise ArgumentError.new("Missing value attribute at index #{index}") unless item[:value].nil? == false

        
        end
      
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