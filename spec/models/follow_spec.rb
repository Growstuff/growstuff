require 'spec_helper'

describe Follow do
  
  context "basic" do
  	before(:each) do
  	  @member1 = FactoryGirl.create(:member)
  	  @member2 = FactoryGirl.create(:member)
  	end

  	it "sends a notification when a follow is created" do
      expect {
        Follow.create(:follower_id => @member1.id, :followed_id => @member2.id)
      }.to change(Notification, :count).by(1)
    end
  end

end