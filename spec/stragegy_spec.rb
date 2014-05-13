require 'spec_helper'
require "uphex-estimation"

describe UpHex::Prediction::Strategy do
	
	context "initialization" do
	  it "does not accept a nil time series" do
	    expect {UpHex::Prediction::Strategy.new(nil).comparison_forecast}.to raise_error(ArgumentError, /Invalid timeseries/)
	  end
  end
	
  context "strategy interface" do
	  it "throws an exception on forecast()" do
	    expect{UpHex::Prediction::Strategy.new(timeseries).forecast}.to raise_error(RuntimeError)
	  end

	  it "throws an exception on comparison_forecast()" do
	    expect {UpHex::Prediction::Strategy.new(timeseries).comparison_forecast}.to raise_error(RuntimeError)
	  end
  end

  def timeseries
    [{:date =>Date.today,:value => 100}, 
      {:date =>Date.today,:value => 200}
    ]
  end
  
end