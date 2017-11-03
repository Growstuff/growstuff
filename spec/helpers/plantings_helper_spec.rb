require 'rails_helper'

describe PlantingsHelper do
  describe "display_planting" do
    let!(:member) { FactoryBot.build(:member, login_name: 'crop_lady') }

    it "does not have a quantity nor a planted from value provided" do
      planting = FactoryBot.build(:planting,
        quantity: nil,
        planted_from: '',
        owner: member)
      result = helper.display_planting(planting)
      expect(result).to eq "crop_lady."
    end

    it "does not have a quantity provided" do
      planting = FactoryBot.build(:planting,
        quantity: nil,
        planted_from: 'seed',
        owner: member)
      result = helper.display_planting(planting)
      expect(result).to eq "crop_lady planted seeds."
    end

    context "when quantity is greater than 1" do
      it "does not have a planted from value provided" do
        planting = FactoryBot.build(:planting,
          quantity: 10,
          planted_from: '',
          owner: member)
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 10 units."
      end

      it "does have a planted from value provided" do
        planting = FactoryBot.build(:planting,
          quantity: 5,
          planted_from: 'seed',
          owner: member)
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 5 seeds."
      end
    end

    context "when quantity is 1" do
      it "does not have a planted from value provided" do
        planting = FactoryBot.build(:planting,
          quantity: 1,
          planted_from: '',
          owner: member)
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 1 unit."
      end

      it "does have a planted from value provided" do
        planting = FactoryBot.build(:planting,
          quantity: 1,
          planted_from: 'seed',
          owner: member)
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 1 seed."
      end
    end
  end
end
