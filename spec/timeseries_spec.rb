require 'spec_helper'
require 'date'
require "uphex-estimation"

describe UpHex::Prediction::TimeSeries do
  
  context "interval initialization" do 
    it "defaults to an interval of 30 days when passed no options" do
      ts = described_class.new(sample_data)
      expect(ts.timespan.span).to equal( 30*60*60*24)
    end
    
    it "accpts an interval key in :seconds" do
      ts = described_class.new(sample_data, {:seconds => 1000})      
      expect(ts.timespan.span).to equal(1000)
      expect(ts.interval[:seconds]).to equal(1000)
    end
    
    it "accpts an interval key in :minutes" do
      ts = described_class.new(sample_data, {:minutes => 90})
      expect(ts.timespan.span).to equal(90*60)
      expect(ts.interval[:minutes]).to equal(90)
    end

    it "accpts an interval key in :hours" do
      ts = described_class.new(sample_data, {:hours => 12})
      expect(ts.timespan.span).to equal(12*60*60)
      expect(ts.interval[:hours]).to equal(12)
    end

    it "accpts an interval key in :days" do
      ts = described_class.new(sample_data, {:days => 3})
      expect(ts.timespan.span).to equal(3*24*60*60)
      expect(ts.interval[:days]).to equal(3)
    end
    
    it "accpts an interval key in :weeks" do
      ts = described_class.new(sample_data, {:weeks => 2})
      expect(ts.timespan.span).to equal(2*7*24*60*60)
      expect(ts.interval[:weeks]).to equal(2)
    end
    
    it "rejects an unknown or bad interval key" do
      expect{described_class.new(sample_data, {:years => 1})}.to raise_error(NoMethodError)
    end        

    it "rejects an unknown or bad interval value (non-coercable numeric)" do
      expect{described_class.new(sample_data, {:days => []})}.to raise_error(ArgumentError,/invalid span/i)
    end        

    it "rejects an unknown or bad interval value (coercable numeric)" do
      expect{described_class.new(sample_data, {:days => "sixteen"})}.to raise_error(ArgumentError,/non-zero span/i)
    end        

    
  end
  
  context "iteration" do
    
    let(:samp) { daily_sample_data(30)}
    
    it "iterates across all data when calling each" do
      ts = described_class.new(samp, {:days => 1})
      
      index = 0
      ts.each do |t|
        expect(t[:value]).to eq samp[index][:value]
        index += 1
      end
      
    end
    
    it "iterates across all data when calling each_with_index" do
      ts = described_class.new(samp, {:days => 1})
      
      ts.each_with_index do |t, index|
        expect(t[:value]).to eq samp[index][:value]
      end
    end
    
    it "iterates across the specified range when calling each_for_range" do
      ts = described_class.new(samp, {:days => 1})
      
      target = (2..13)
      index = target.begin
      ts.each_for_range(target) do |t|
        expect(t[:value]).to eq samp[index][:value]
        index += 1
      end
      
    end

    it "iterates across the specified range when calling each_with_index_for_range" do
      ts = described_class.new(samp, {:days => 1})
      
      target = (5..11)
      offset = target.begin
      ts.each_with_index_for_range(target) do |t, index|
        expect(t[:value]).to eq samp[offset+index][:value]
      end
      
    end
    
    
  end
  
  context "data subsetting" do 
    
    let (:samp) { daily_sample_data(30)}
    
    it "returns a single row of source data when calling at(index) with an integer" do
      ts = described_class.new(samp, {:days => 1})
      
      offset = 2
      subset = ts[offset]
      expect(subset[:value]).to eq samp[offset][:value]      
    end 

    it "returns an array of source data when calling [index] with a range" do
      ts = described_class.new(samp, {:days => 1})
      
      target = (11..19)
      offset = target.begin
      subset = ts[target]

      expect(subset.length).to eq target.to_a.length      
    end 


    
    it "raise TypeError when calling at with a non-numeric type" do
      ts = described_class.new(samp, {:days => 1})
      
      expect { ts[{:a => "b"}] }.to raise_error(TypeError)
      expect {ts["fourtyfour"] }.to raise_error(TypeError)
      expect {ts["6"]}.to raise_error(TypeError)
      expect {ts[:a]}.to raise_error(TypeError)
    end
  end
  
  context "data ordering" do 
    it "does nothing when data is already sorted descending" do  
      samp = daily_sample_data(30)      
      expect(samp.length).to eq 30
      
      ts = described_class.new(samp, {:days => 1})

      ts.each_with_index do |t,i|
        expect(t[:value]).to eq samp[i][:value]
      end
    end
    
    it "sorts series by date descending" do
      samp = daily_sample_data(30)      
      expect(samp.length).to eq 30
      
      orig = samp.dup
      samp.shuffle!
      
      ts = described_class.new(samp, {:days => 1})

      ts.each_with_index do |t,i|
        expect(t[:value]).to eq orig[i][:value]
      end      
      
      
    end
    
  end
  
  def daily_sample_data(n=1)    
    1.upto(n).collect do |i|
      {:date => Date.today+i, :value => (i-1)*1000}
    end
  end

  def sample_data
    [{:date => Date.today, :value => 0}]
  end

    
end