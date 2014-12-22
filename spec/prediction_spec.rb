require 'spec_helper'
require 'uphex-estimation'

describe UpHex::Prediction::Prediction do
	context "value handling" do
	  it 'initializes variables with sane default values' do
	    value = 2.0
	    p = described_class.new(Date.today, value)
	    expect(p.low_range).to eq value
	    expect(p.high_range).to eq value
	    expect(p.predicted_value).to eq value
	    expect(p.outlier).to eq false
	  end
  end
end
