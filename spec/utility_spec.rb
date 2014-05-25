require 'spec_helper'
require 'uphex-estimation'

describe UpHex::Prediction::Utility do
  context "inverse cummulative distribution function" do
    it "properly handles negative values" do
      v = described_class.cdf_inverse(-1)
      expect(v).to equal(0.0)
      
      v = described_class.cdf_inverse(-50000)
      expect(v).to equal(0.0)

      v = described_class.cdf_inverse(-2.2)
      expect(v).to equal(0.0)
    end
    
    it "properly handles zero" do
      v = described_class.cdf_inverse(0)
      expect(v).to equal(0.0)
    end
    
    it "properly handles the nil value" do
      expect {described_class.cdf_inverse(nil)}.to raise_error(ArgumentError)
    end
    
    it 'properly handles too-large positive values' do
      v = described_class.cdf_inverse(1)
      expect(v).to equal(0.0)
      
      v = described_class.cdf_inverse(15.0)
      expect(v).to equal(0.0)
      
      v = described_class.cdf_inverse(250000.0)
      expect(v).to equal(0.0)
      
    end
    
    it 'properly handles positive fractional values' do
      v = described_class.cdf_inverse(0.05)
      expect(v).to be_within(0.01).of(-1.6448)
      
      v = described_class.cdf_inverse(0.01)
      expect(v).to be_within(0.01).of(-2.3263)

      v = described_class.cdf_inverse(0.51)
      expect(v).to be_within(0.01).of(0.02506)

      v = described_class.cdf_inverse(0.99)
      expect(v).to be_within(0.01).of(2.3263)
      
      
      
    end
    
  end

  context "sample variance calcuation" do
    
    it "returns 0.0 for an empty array" do
      v = described_class.sample_variance([])
      expect(v).to equal(0.0)
    end
    
    it "returns the value for a single-value array" do
      v = described_class.sample_variance([25])
      expect(v).to equal(25)
    end
    
    it "throws an exception when passed a non-array" do
      # nil fails on .length call
      expect {described_class.sample_variance(nil)}.to raise_error(NoMethodError)
      
      # class-without.length fails on .length call
      expect {described_class.sample_variance(0.0)}.to raise_error(NoMethodError)
      
      # class-with.length, subset, but without double-coerceable value fails on subset call
      expect { described_class.sample_variance({a: "eh", b: "bee"})}.to raise_error(TypeError)
      
      # class-with.length, subset, and array-coerceable value in subset fails otherwise
      v = described_class.sample_variance({a: [0,1,2]})
      expect(v).to equal(nil)
      
    end
    
    it "properly calculates sample variance for integers" do
      values = [2, 6, 1, 10, 5, 9, 4, 7, 3, 8]
      sample_variance = described_class.sample_variance(values)
      expect(sample_variance).to be_within(0.01).of(9.166)
    end

    it "properly calculates sample variance for floats" do
      values = [3.14, 1.0, 99.99, 515.0]
      sample_variance = described_class.sample_variance(values)
      expect(sample_variance).to be_within(0.01).of(59801.1234)
    end
    
    
  end
end
