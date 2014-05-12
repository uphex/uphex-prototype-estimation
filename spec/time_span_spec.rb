require 'spec_helper'
require 'date'

require "uphex-estimation"

describe UpHex::Prediction::TimeSpan do
      
  describe "timespan initialization" do
    
    it "creates a span in seconds" do      
      span_in_seconds = 60      
      ts = UpHex::Prediction::TimeSpan.from_seconds(span_in_seconds)      
      expect(ts.span).to eq span_in_seconds      
    end
    
    it "creates a span in minutes" do
      minutes = 10      
      ts = UpHex::Prediction::TimeSpan.from_minutes(minutes)
      expect(ts.span).to eq minutes*60
    end
    
    it "creates a span in hours" do
      hours = 3
      ts = UpHex::Prediction::TimeSpan.from_hours(hours)
      expect(ts.span).to eq hours*60*60
    end
    
    it 'creates a span in days' do
      days = 4
      ts = UpHex::Prediction::TimeSpan.from_days(days)
      expect(ts.span).to eq days*60*60*24
    end    
    
    it 'creates a span in weeks' do
      weeks = 3
      ts = UpHex::Prediction::TimeSpan.from_weeks(weeks)
      expect(ts.span).to eq weeks*(60*60*24*7)
      
    end
    
    it 'creates a span from a hash (seconds)' do
      seconds = 30
      hash = {:seconds => 30}
      ts = UpHex::Prediction::TimeSpan.from_hash(hash)
      expect(ts.span).to eq seconds
    end

    it 'creates a span from a hash (minutes)' do
      hash = {:minutes => 5}
      ts = UpHex::Prediction::TimeSpan.from_hash(hash)
      expect(ts.span).to eq 5*60
    end

    it 'creates a span from a hash (hours)' do
      hash = {:hours => 10}
      ts = UpHex::Prediction::TimeSpan.from_hash(hash)
      expect(ts.span).to eq 10*60*60
    end

    it 'creates a span from a hash (days)' do
      hash = {:days => 16}
      ts = UpHex::Prediction::TimeSpan.from_hash(hash)
      expect(ts.span).to eq 16*60*60*24
    end

    it 'creates a span from a hash (weeks)' do
      hash = {:weeks => 2}
      ts = UpHex::Prediction::TimeSpan.from_hash(hash)
      expect(ts.span).to eq (60*60*24*7*2)
    end
    
    it 'creates a span from two Time instances' do
      diff = 300
      t0 = Time.now
      t1 = Time.now + diff
      ts = UpHex::Prediction::TimeSpan.from_times(t0,t1)
      expect(ts.span).to eq(diff)
    end    
    
    it "rounds fractional seconds down" do
      span = 30.131313
      ts = UpHex::Prediction::TimeSpan.from_seconds(span)
      expect(ts.span).to eq 30.0
    end
    
    it "rounds fractional seconds up" do
      span = 30.51
      ts = UpHex::Prediction::TimeSpan.from_seconds(span)
      expect(ts.span).to eq 31.0
    end
  end
  
  
  describe "timespan initialize with odd values" do
    
    it "converts bad string values to numbers" do
      ts = UpHex::Prediction::TimeSpan.from_seconds("bob")
      expect(ts.span).to eq 0.0
    end        
    
    it "converts numeric strings to numbers" do
      ts = UpHex::Prediction::TimeSpan.from_seconds("15")
      expect(ts.span).to eq 15.0
    end
    
    it "converts negative numeric strings to numbers" do
      ts = UpHex::Prediction::TimeSpan.from_seconds("-15")
      expect(ts.span).to eq 15.0
    end
    
    it "converts negative numbers to positive numbers" do
      ts = UpHex::Prediction::TimeSpan.from_seconds(-30.0)
      expect(ts.span).to eq 30.0
    end
    
    it "handles bad types (array)" do      
      expect{ UpHex::Prediction::TimeSpan.from_seconds([])} .to raise_error(ArgumentError, /span type/)      
    end
    
    it "handles bad types (hash)" do
      expect{ UpHex::Prediction::TimeSpan.from_seconds([:test => "data"])} .to raise_error(ArgumentError, /span type/)      
    end
    
    it "handles bad types (class)" do
      expect{ UpHex::Prediction::TimeSpan.from_seconds(13.class)} .to raise_error(ArgumentError, /span type/)      
    end
    
    it "handles bad types (span, string)" do
      expect {UpHex::Prediction::TimeSpan.from_times(Time.now, "yesterday")}.to raise_error(ArgumentError, /time/)
    end

    it "handles bad types (span, array)" do
      expect {UpHex::Prediction::TimeSpan.from_times(Time.now, [])}.to raise_error(ArgumentError, /time/)
    end

    it "handles bad types (array, hash)" do
      expect {UpHex::Prediction::TimeSpan.from_times([], {})}.to raise_error(ArgumentError, /time/)
    end
    
    it "handles hases with bad keys" do
      expect {UpHex::Prediction::TimeSpan.from_hash(:test => "data")}.to raise_error(NoMethodError)
    end
    
    it "handles hashes with bad values (non-numeric coercable)" do
      ts = UpHex::Prediction::TimeSpan.from_hash(:days => "data")
      expect(ts.span).to eq 0.0
    end

    it "handles hashes with bad values (non-numeric not coercable)" do
      expect { UpHex::Prediction::TimeSpan.from_hash(:days => [])}.to raise_error(ArgumentError, /span type/i)      
    end        
  end
    
  describe "timespan advances along span" do
    
    it "advances a time by span and return a time" do
      seconds = 30
      t0 = Time.now
      ts = UpHex::Prediction::TimeSpan.from_seconds(seconds)
      t1 = ts.advance(t0)
      expect(t1-t0).to eq seconds    
    end    
    
    it "fails when attempting to advance a non-time value (string)" do
      ts = UpHex::Prediction::TimeSpan.from_seconds(10)
      expect { ts.advance('george') }.to raise_error(ArgumentError,/time/i)      
    end

    it "fails when attempting to advance a non-time value (float)" do
      ts = UpHex::Prediction::TimeSpan.from_seconds(10)
      expect { ts.advance(30.0) }.to raise_error(ArgumentError,/time/i)      
    end

    it "fails when attempting to advance a non-time value (array)" do
      ts = UpHex::Prediction::TimeSpan.from_seconds(10)
      expect { ts.advance([]) }.to raise_error(ArgumentError,/time/i)      
    end

    it "fails when attempting to advance a non-time value (hash)" do
      ts = UpHex::Prediction::TimeSpan.from_seconds(10)
      expect { ts.advance({:george => "1"}) }.to raise_error(ArgumentError,/time/i)      
    end

  end
end