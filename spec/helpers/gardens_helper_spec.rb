require 'rails_helper'

describe GardensHelper do
  
  describe '#area_abbreviations' do
    it "converts square metre to m<sup>2</sup>" do
      expect(helper.area_abbreviations('square metre')).to eq('m<sup>2</sup>')
    end

    it "converts square foot to sqft" do
      expect(helper.area_abbreviations('square foot')).to eq('sqft')
    end

    it "converts hectare to ha" do
      expect(helper.area_abbreviations('hectare')).to eq('ha')
    end

    it "returns acre" do
      expect(helper.area_abbreviations('acre')).to eq('acre')
    end

    it "returns '' when no data is provided" do
      expect(helper.area_abbreviations('')).to eq('')
    end
  end

end