require 'spec_helper'
require "uphex-estimation"

describe UpHex::Prediction::ExponentialMovingAverageStrategy do


  context "exponential moving average initialization" do

    it "needs two or more source data rows" do
      ts = UpHex::Prediction::TimeSeries.new(single_data_set, {:days => 1})
      expect {described_class.new(ts)}.to raise_error(ArgumentError, /invalid data set length/i)
    end            
  end
  

  context "exponential moving average forecast" do

	  let(:timeseries) { UpHex::Prediction::TimeSeries.new(sourcedata, {:days => 1})}
	  let(:ema) { UpHex::Prediction::ExponentialMovingAverageStrategy.new(timeseries)}
    
    let (:prng) { Random.new }
    let (:truth) { truthdata() }

    error_tolerence = 0.001

    it "performs a 15-day EMA with interval ratio 5, a variable number of periods into the future" do
      forecast_periods = 3
      # compute EMA on records 0..(5 to 10)
      range = Range.new(0, 5+prng.rand(5))
      results = ema.forecast(forecast_periods,:period_count => 15, :interval_ratio => 5, :range => range)
      
			diffs = []

      expect(results.length).to eq forecast_periods
      offset = range.end + 1

      results.each_with_index do |r, index|
        t = truth[index + offset]
        # expect the % difference between the predicted and expected value to fall within our error tolerence
        diff = (r[:forecast] - t[0]).abs / t[0]
        expect(diff).to be <= error_tolerence
				diffs << diff
        diff = (r[:low] - t[1]).abs / t[1]
        expect(diff).to be <= error_tolerence

        diff = (r[:high] - t[2]).abs / t[2]
        expect(diff).to be <= error_tolerence 
      end
    end
    
    it "performs a 15-day EMA with interval ratio 5 via comparison_forecast" do
      
      # compute EMA on records 0..(6 to 16)
      #range = Range.new(0,6+prng.rand(10))
      range = 0..15
      
      expected_period_count = timeseries.length - range.end - 1

      periods = 3
      results = ema.comparison_forecast(periods, :period_count => 15, :interval_ratio => 5, :range => range)                  
      expect(results.length).to eq expected_period_count

      offset = range.end + 1      
      results.each_with_index do |r, index|
        t = truth[offset + index ]
        diff = (r[:forecast] - t[0]).abs / t[0]
        #expect(diff).to be <= error_tolerence     
        
        diff = (r[:low] - t[1]).abs / t[1]
        #expect(diff).to be <= error_tolerence

        diff = (r[:high] - t[2]).abs / t[2]
        #expect(diff).to be <= error_tolerence    
      end
      
    end
          
  end
  
  
  
  def sourcedata
    ## taken from https://gist.github.com/fj/eaec085ac860d6c10881 results.csv
    [
      {:date => Date.parse("2010-03-01"),:value => 6602},
      {:date => Date.parse("2010-03-02"),:value => 7298},
      {:date => Date.parse("2010-03-03"),:value => 6885},
      {:date => Date.parse("2010-03-04"),:value => 7106},
      {:date => Date.parse("2010-03-05"),:value => 6475},
      {:date => Date.parse("2010-03-06"),:value => 4710},
      {:date => Date.parse("2010-03-07"),:value => 4573},
      {:date => Date.parse("2010-03-08"), :value => 6325},
      {:date => Date.parse("2010-03-09"), :value => 6199},
      {:date => Date.parse("2010-03-10"), :value => 6242},
      {:date => Date.parse("2010-03-11"), :value => 6805},
      {:date => Date.parse("2010-03-12"), :value => 6054},
      {:date => Date.parse("2010-03-13"), :value => 4677},
      {:date => Date.parse("2010-03-14"), :value => 5685},
      {:date => Date.parse("2010-03-15"), :value => 8287},
      {:date => Date.parse("2010-03-16"), :value => 7735},
      {:date => Date.parse("2010-03-17"), :value => 6736},
      {:date => Date.parse("2010-03-18"), :value => 7020},
      {:date => Date.parse("2010-03-19"), :value => 8196},
      {:date => Date.parse("2010-03-20"), :value => 8570},
      {:date => Date.parse("2010-03-21"), :value => 6361},
      {:date => Date.parse("2010-03-22"), :value => 8161},
      {:date => Date.parse("2010-03-23"), :value => 8068},
      {:date => Date.parse("2010-03-24"), :value => 6460},
      {:date => Date.parse("2010-03-25"), :value => 6446},
      {:date => Date.parse("2010-03-26"), :value => 5692},
      {:date => Date.parse("2010-03-27"), :value => 4454},
      {:date => Date.parse("2010-03-28"), :value => 4640},
      {:date => Date.parse("2010-03-29"), :value => 6443},
      {:date => Date.parse("2010-03-30"), :value => 6136},
      {:date => Date.parse("2010-03-31"), :value => 5843}          
    ]    
  end
  
  def truthdata
    ## taken from https://gist.github.com/fj/eaec085ac860d6c10881 results.csv
    ## predicted, low range, high range
    [
      [6602,6602,6602],
      [6689,3644,9734],
      [6713.5,4762.25,8664.75],
      [6762.5625,4889.333333,8635.791667],
      [6726.617188,5007.173828,8446.060547],
      [6474.540039,3334.445313,9614.634766],
      [6236.847534,2233.562317,10240.13275],
      [6247.866592,2761.383972,9734.349213],
      [6241.758268,3164.362058,9319.154479],
      [6241.788485,3506.207678,8977.369291],
      [6312.189924,3603.76216,9020.617688],
      [6279.916184,3715.019951,8844.812416],
      [6079.551661,3144.000256,9015.103066],
      [6030.232703,3187.711136,8872.754271],
      [6312.328615,2967.604522,9657.052708],
      [6490.162538,2953.474231,10026.85085],
      [6520.892221,3138.025752,9903.75869],
      [6583.280693,3270.959515,9895.601872],
      [6784.870607,3264.586884,10305.15433],
      [7008.011781,3261.956618,10754.06694],
      [6927.135308,3226.849076,10627.42154],
      [7081.368395,3300.231125,10862.50566],
      [7204.697345,3399.224803,11010.16989],
      [7111.610177,3329.938576,10893.28178],
      [7028.408905,3282.971765,10773.84604],
      [6861.357792,3031.86658,10690.849],
      [6560.438068,2473.150735,10647.7254],
      [6320.383309,2073.294895,10567.47172],
      [6335.710396,2221.144852,10450.27594],
      [6310.746596,2307.9339,10313.55929],
      [6252.278272,2314.67962,10189.87692]

    ]
  end
  
  def single_data_set
    # [{:date => Date.today, :value => 1}]
    sourcedata()[0...1]
  end
  
  

end