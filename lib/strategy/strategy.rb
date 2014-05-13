
module UpHex
	module Prediction		
  	class Strategy
        
	    def initialize(timeseries)
      
	      raise ArgumentError.new("Invalid timeseries") if timeseries.nil?
                        
	      @timeseries = timeseries
	    end
    
	    def forecast(*opts)
	      raise "Unimplemented strategy"
	    end
  
	    def comparison_forecast(*opts)
	      raise "Unimplemented strategy"
	    end
  
	  end
	end
end