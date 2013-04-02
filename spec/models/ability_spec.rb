require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @ability = Ability.new(@member)
  end

  context "notifications" do
    it 'member can view their own notifications' do
      @notification = FactoryGirl.create(:notification, :recipient => @member)
      @ability.should be_able_to(:read, @notification)
    end

    it "member can't view someone else's notifications" do
      @notification = FactoryGirl.create(:notification,
        :recipient => FactoryGirl.create(:member)
      )
      @ability.should_not be_able_to(:read, @notification)
    end
    it "member can't send messages to themself" do
      @ability.should_not be_able_to(:create,
        FactoryGirl.create(:notification,
          :recipient => @member,
          :sender => @member
        )
      )
    end
    it "member can send messages to someone else" do
      @ability.should be_able_to(:create,
        FactoryGirl.create(:notification,
          :recipient => FactoryGirl.create(:member),
          :sender => @member
        )
      )
    end
  end

  context "crop wrangling" do

    before(:each) do
      @crop = FactoryGirl.create(:crop)
    end

    context "standard member" do
      it "can't manage crops" do
        @ability.should_not be_able_to(:create, Crop)
        @ability.should_not be_able_to(:update, @crop)
        @ability.should_not be_able_to(:destroy, @crop)
      end

      it "can read crops" do
        @ability.should be_able_to(:read, @crop)
      end
    end

    context "crop wrangler" do
      before(:each) do
        @role = FactoryGirl.create(:crop_wrangler)
        @member.roles << @role
        @cw_ability = Ability.new(@member)
      end

      it "has crop_wrangler role" do
        @member.has_role?(:crop_wrangler).should be true
      end

      it "can create crops" do
        @cw_ability.should be_able_to(:create, Crop)
      end
      it "can update crops" do
        @cw_ability.should be_able_to(:update, @crop)
      end
      it "can destroy crops" do
        @cw_ability.should be_able_to(:destroy, @crop)
      end
    end
  end

end
