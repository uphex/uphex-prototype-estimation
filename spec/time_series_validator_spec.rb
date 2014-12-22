require 'spec_helper'
require 'uphex-estimation'

describe UpHex::Prediction::TimeSeriesValidator do
	context "source data validation" do
    ## bad or missing data types
    it "does not accept a null data source" do
      expect(described_class.new(nil).valid?).to eq false
    end

    it 'does not accept a non-array data source' do
      expect(described_class.new("1234").valid?).to eq false
      expect(described_class.new(1234).valid?).to eq false
      expect(described_class.new(:zurb).valid?).to eq false
      expect(described_class.new((1..13)).valid?).to eq false
    end

    it "does not accept an empty data source" do
     expect(described_class.new([]).valid?).to eq false
    end
    ## badly formatted source data

    it 'does not accept non-hash entries' do
      expect(described_class.new([[]]).valid?).to eq false
    end

    it 'does not accept non-hash entries for non-zero indexes' do
      expect(described_class.new([{:date => Date.today, :value => 0},[]]).valid?).to eq false
    end

    ### date key
    it "does not accept any missing date entry" do
      sourcedata = [{:value => 0}]
      expect(described_class.new(sourcedata).valid?).to eq false
    end

    it "does not accept any invalid date entries" do
      sourcedata = [{:date => :z, :value => 0}]
      expect(described_class.new(sourcedata).valid?).to eq false
    end

    ### value key
    it "does not accept a missing value entry" do
      sourcedata = [{:date => Date.today}]
      expect(described_class.new(sourcedata).valid?).to eq false
    end
  end
end
