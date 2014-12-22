module UpHex
	module Prediction
		class TimeSeriesValidator
			def initialize(data)
				@source_array = data
			end

			def valid?
				# require the source array to be non-nil
        return false if @source_array.nil?

	      # require the source array to be an array
	      return false unless @source_array.is_a?(Array)

		    # require the source array to have a non-zero length
		    return false  if @source_array.length == 0

		    # validate the format of every entry of the source_array

		    @source_array.each_with_index do |item, index|
		      # not a hash
		      return false unless item.is_a?(Hash)

		      # missing :date
		      return false unless item[:date].nil? == false
		      # non-date :date
		      return false unless item[:date].is_a?(Date)

		      # missing :value
		      return false unless item[:value].nil? == false
		    end

				true
			end
		end
	end
end
