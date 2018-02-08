require 'spec_helper'

describe Follow do
  before(:each) do
    @member1 = FactoryBot.create(:member)
    @member2 = FactoryBot.create(:member)
  end

  it "sends a notification when a follow is created" do
    expect do
      Follow.create(follower_id: @member1.id, followed_id: @member2.id)
    end.to change(Notification, :count).by(1)
  end

  it "does not delete any members when follow is deleted" do
    expect do
      follow = Follow.create(follower_id: @member1.id, followed_id: @member2.id)
      follow.destroy
    end.not_to change(Member, :count)
  end

  context "when follow is created" do
    before(:each) do
      @follow = Follow.create(follower_id: @member1.id, followed_id: @member2.id)
    end

    it "should not duplicate follows" do
      expect(Follow.create(follower_id: @member1.id, followed_id: @member2.id)).not_to be_valid
    end

    it "should list users in following/follower collections when follow is created" do
      expect(@member1.followed).to include(@member2)
      expect(@member2.followers).to include(@member1)
    end

    it "should no longer list users in following/follower collections when follow is deleted" do
      @follow.destroy
      expect(@member1.followed).not_to include(@member2)
      expect(@member2.followers).not_to include(@member1)
    end
  end
end
