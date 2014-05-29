require 'spec_helper'
require 'CSV'
require 'uphex-estimation'
require 'timeseries/timeseries'

describe UpHex::Prediction::HoltWintersStrategy do
  
  let(:source) { source_data() }
  let(:truth)  { truth_data()  }
  let(:test_tolerance) { 0.001 }
  context 'HoltWinters alpha-only forecast' do
    it 'properly projects 1 period into the future for the first two years of data' do
      
      ts = UpHex::Prediction::TimeSeries.new(source, {:days => 365})
      
      hw = described_class.new(ts)
      range = 0...730
      forecasts = hw.forecast(1, :range => range, 
                              :confidence_level => 0.99, 
                              :model => {:alpha => 0.1})
      
      expect(forecasts.length).to be(1)
      
      expect(forecasts[0][:forecast]).to be_within(test_tolerance).of(truth[range.max+1][:pred])
      expect(forecasts[0][:low]).to be_within(test_tolerance).of(truth[range.max+1][:low])
      expect(forecasts[0][:high]).to be_within(test_tolerance).of(truth[range.max+1][:high])
    end
    
    it 'properly projects 1 period into the future for a random set of data' do
      ts = UpHex::Prediction::TimeSeries.new(source, {:days => 365})

      hw = described_class.new(ts)
      range = 0...(730 + Random.rand(source.length-1-(365*2)))

      forecasts = hw.forecast(1, :range => range, 
                              :confidence_level => 0.99, 
                              :model => {:alpha => 0.1})
      
      expect(forecasts.length).to be(1)
      
      expect(forecasts[0][:forecast]).to be_within(test_tolerance).of(truth[range.max+1][:pred])
      expect(forecasts[0][:low]).to be_within(test_tolerance).of(truth[range.max+1][:low])
      expect(forecasts[0][:high]).to be_within(test_tolerance).of(truth[range.max+1][:high])

    end
    
  end
  
  context 'HoltWinters alpha-only comparison_forecast' do
    it 'properly performs comparison forecast for a known range, 1 day at a time' do
      ts = UpHex::Prediction::TimeSeries.new(source, {:days => 365})
      
      hw = described_class.new(ts)
      range = 0...730
      forecasts = hw.comparison_forecast(1, :range => range, 
                              :confidence_level => 0.99, 
                              :model => {:alpha => 0.1})
      

      expect(forecasts.length).to be(source.length-range.max)
      

      expect(forecasts[0][:forecast]).to be_within(test_tolerance).of(truth[range.max+1][:pred])
      expect(forecasts[0][:low]).to be_within(test_tolerance).of(truth[range.max+1][:low])
      expect(forecasts[0][:high]).to be_within(test_tolerance).of(truth[range.max+1][:high])
      
    end
    
    it 'properly performs comparison forecast for a known range, 3 days at a time' do
      ts = UpHex::Prediction::TimeSeries.new(source, {:days => 365})

      hw = described_class.new(ts)
      range = 0...730
      forecasts = hw.comparison_forecast(3, :range => range, 
                              :confidence_level => 0.99, 
                              :model => {:alpha => 0.1})

      expect(forecasts.length).to be(source.length-range.max)

      # the truth data was computed using a step of 1 so we can't compare against anything other than the first projection
      expect(forecasts[0][:forecast]).to be_within(test_tolerance).of(truth[range.max+1][:pred])
      expect(forecasts[0][:low]).to be_within(test_tolerance).of(truth[range.max+1][:low])
      expect(forecasts[0][:high]).to be_within(test_tolerance).of(truth[range.max+1][:high])
      
    end    
    
    it 'properly performs a comparison forecast 10 times for a random range, with a random number of periods foreward' do
      
      ts = UpHex::Prediction::TimeSeries.new(source, {:days => 365})

      hw = described_class.new(ts)
      3.times do
        range = 0...(730 + Random.rand(source.length-1-(365*2)))
        foreward = 1 + Random.rand(6)
        forecasts = hw.comparison_forecast(foreward, :range => range, 
                                :confidence_level => 0.99, 
                                :model => {:alpha => 0.1})

        expect(forecasts.length).to be(source.length-range.max)

        # the truth data was computed using a step of 1 so we can't compare against anything other than the first projection
        expect(forecasts[0][:forecast]).to be_within(test_tolerance).of(truth[range.max+1][:pred])
        expect(forecasts[0][:low]).to be_within(test_tolerance).of(truth[range.max+1][:low])
        expect(forecasts[0][:high]).to be_within(test_tolerance).of(truth[range.max+1][:high])
      end
      
    end
    
  end
end

def source_data(path='data/visitors.csv')
  items = []
  CSV.open(path, "r", :headers => true).each do |line|
    items << {:date => Date.parse(line[0]), :value => line[1].to_f}
  end
  # sort by date
  items.sort { |l,r| l[:date] <=> r[:date]}
end

def truth_data(path='data/results.csv')
  items = []
  CSV.open(path, "r", :headers => true).each do |line|
    pred = (line[2] == "NA")? Float::NAN : line[2].to_f
    low = (line[3] == "NA")? Float::NAN : line[3].to_f
    high = (line[4] == "NA")? Float::NAN : line[4].to_f
    items << {:date => Date.parse(line[0]), :value => line[1].to_f, :pred => pred, :low => low, :high => high}
  end
  items
end