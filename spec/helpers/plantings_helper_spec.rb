require 'rails_helper'

describe PlantingsHelper do
  describe "display_days_before_maturity" do
    it "handles nil planted_at, nil finished_at, non-nil days_until_maturity" do
      planting = FactoryGirl.build(:planting,
        quantity: 5,
        planted_at: nil,
        finished_at: nil,
        days_before_maturity: 17
      )
      result = helper.display_days_before_maturity(planting)
      expect(result).to eq "unknown"
    end

    it "handles non-nil planted_at and d_b_m, nil finished_at" do
      planting = FactoryGirl.build(:planting,
        quantity: 5,
        planted_at: Date.current,
        finished_at: nil,
        days_before_maturity: 17
      )
      result = helper.display_days_before_maturity(planting)
      expect(result).to eq "17"
    end

    it "handles completed plantings" do
      planting = FactoryGirl.build(:planting, finished: true)
      result = helper.display_days_before_maturity(planting)
      expect(result).to eq "0"
    end

    it "handles plantings that should have finished" do
      planting = FactoryGirl.build(:planting,
        quantity: 5,
        planted_at: Date.new(0, 1, 1),
        finished_at: nil,
        days_before_maturity: "17"
      )
      result = helper.display_days_before_maturity(planting)
      expect(result).to eq "0"
    end

    it "handles nil d_b_m and nil finished_at" do
      planting = FactoryGirl.build(:planting,
        quantity: 5,
        planted_at: Date.new(2012, 5, 12),
        finished_at: nil,
        days_before_maturity: nil
      )
      result = helper.display_days_before_maturity(planting)
      expect(result).to eq "unknown"
    end

    it "handles finished_at dates in the future" do
      planting = FactoryGirl.build(:planting,
        quantity: 5,
        planted_at: Date.current,
        finished_at: Date.current + 5,
        days_before_maturity: nil
      )
      result = helper.display_days_before_maturity(planting)
      expect(result).to eq "5"
    end
  end

  describe "display_planting" do
    let!(:member) { FactoryGirl.build(:member, login_name: 'crop_lady') }

    it "does not have a quantity nor a planted from value provided" do
      planting = FactoryGirl.build(:planting,
        quantity: nil,
        planted_from: '',
        owner: member
      )
      result = helper.display_planting(planting)
      expect(result).to eq "crop_lady."
    end

    it "does not have a quantity provided" do
      planting = FactoryGirl.build(:planting,
        quantity: nil,
        planted_from: 'seed',
        owner: member
      )
      result = helper.display_planting(planting)
      expect(result).to eq "crop_lady planted seeds."
    end

    context "when quantity is greater than 1" do
      it "does not have a planted from value provided" do
        planting = FactoryGirl.build(:planting,
          quantity: 10,
          planted_from: '',
          owner: member
        )
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 10 units."
      end

      it "does have a planted from value provided" do
        planting = FactoryGirl.build(:planting,
          quantity: 5,
          planted_from: 'seed',
          owner: member
        )
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 5 seeds."
      end
    end

    context "when quantity is 1" do
      it "does not have a planted from value provided" do
        planting = FactoryGirl.build(:planting,
          quantity: 1,
          planted_from: '',
          owner: member
        )
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 1 unit."
      end

      it "does have a planted from value provided" do
        planting = FactoryGirl.build(:planting,
          quantity: 1,
          planted_from: 'seed',
          owner: member
        )
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 1 seed."
      end
    end
  end
end
