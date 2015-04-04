require 'rails_helper'

describe PlantingsHelper do
  describe "display_planting" do

    before(:each) do
      @member = FactoryGirl.build(:member,
        :login_name => 'crop_lady'
      )
    end

    it "neither quantity nor planted from provided" do
      planting = FactoryGirl.build(:planting,
        :quantity => nil,
        :planted_from => '',
        :owner => @member
      )
      result = helper.display_planting(planting)
      result.should eq "crop_lady."
    end

    it "quantity not provided" do
      planting = FactoryGirl.build(:planting,
        :quantity => nil,
        :planted_from => 'seed',
        :owner => @member
      )
      result = helper.display_planting(planting)
      result.should eq "crop_lady planted seeds."
    end

    context "multiple quantity" do
      it "planted_from not provided" do
        planting = FactoryGirl.build(:planting,
          :quantity => 10,
          :planted_from => '',
          :owner => @member
        )
        result = helper.display_planting(planting)
        result.should eq "crop_lady planted 10 units."
      end

      it "planted_from provided" do
        planting = FactoryGirl.build(:planting,
          :quantity => 5,
          :planted_from => 'seed',
          :owner => @member
        )
        result = helper.display_planting(planting)
        result.should eq "crop_lady planted 5 seeds."
      end
    end

    context "single quantity" do
      it "planted_from not provided" do
        planting = FactoryGirl.build(:planting,
          :quantity => 1,
          :planted_from => '',
          :owner => @member
        )
        result = helper.display_planting(planting)
        result.should eq "crop_lady planted 1 unit."
      end

      it "planted_from provided" do
        planting = FactoryGirl.build(:planting,
          :quantity => 1,
          :planted_from => 'seed',
          :owner => @member
        )
        result = helper.display_planting(planting)
        result.should eq "crop_lady planted 1 seed."
      end

    end

  end
end