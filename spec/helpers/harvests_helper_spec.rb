require 'rails_helper'

describe HarvestsHelper do
  describe "display_quantity" do
    it "blank" do
      harvest = FactoryBot.create(:harvest,
        quantity: nil,
        weight_quantity: nil)
      result = helper.display_quantity(harvest)
      result.should eq 'not specified'
    end

    it '3 individual' do
      harvest = FactoryBot.create(:harvest,
        quantity: 3,
        unit: 'individual',
        weight_quantity: nil)
      result = helper.display_quantity(harvest)
      result.should eq '3'
    end

    it '1 bunch' do
      harvest = FactoryBot.create(:harvest,
        quantity: 1,
        unit: 'bunch',
        weight_quantity: nil)
      result = helper.display_quantity(harvest)
      result.should eq '1 bunch'
    end

    it '3 bunches' do
      harvest = FactoryBot.create(:harvest,
        quantity: 3,
        unit: 'bunch',
        weight_quantity: nil)
      result = helper.display_quantity(harvest)
      result.should eq '3 bunches'
    end

    it '3 kg' do
      harvest = FactoryBot.create(:harvest,
        quantity: nil,
        unit: nil,
        weight_quantity: 3,
        weight_unit: 'kg')
      result = helper.display_quantity(harvest)
      result.should eq '3 kg'
    end

    it '3 individual weighing 3 kg' do
      harvest = FactoryBot.create(:harvest,
        quantity: 3,
        unit: 'individual',
        weight_quantity: 3,
        weight_unit: 'kg')
      result = helper.display_quantity(harvest)
      result.should eq '3, weighing 3 kg'
    end

    it '3 bunches weighing 3 kg' do
      harvest = FactoryBot.create(:harvest,
        quantity: 3,
        unit: 'bunch',
        weight_quantity: 3,
        weight_unit: 'kg')
      result = helper.display_quantity(harvest)
      result.should eq '3 bunches, weighing 3 kg'
    end
  end
end
