require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @ability = Ability.new(@member)
  end

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

end
