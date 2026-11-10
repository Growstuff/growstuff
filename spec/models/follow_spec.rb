# frozen_string_literal: true

require 'spec_helper'

describe Follow do
  before do
    @member1 = create(:member)
    @member2 = create(:member)
  end

  it "sends a notification when a follow is created" do
    expect do
      described_class.create(follower_id: @member1.id, followed_id: @member2.id)
    end.to change(Notification, :count).by(1)
  end

  it "does not delete any members when follow is deleted" do
    expect do
      follow = described_class.create(follower_id: @member1.id, followed_id: @member2.id)
      follow.destroy
    end.not_to change(Member, :count)
  end

  context "when follow is created" do
    before do
      @follow = described_class.create(follower_id: @member1.id, followed_id: @member2.id)
    end

    it "does not duplicate follows" do
      expect(described_class.create(follower_id: @member1.id, followed_id: @member2.id)).not_to be_valid
    end

    it("lists the followed member in the follower's followed") { expect(@member1.followed).to include(@member2) }
    it("lists the follower in the followed member's followers") { expect(@member2.followers).to include(@member1) }

    context "when the follow is deleted" do
      before { @follow.destroy }

      it("no longer lists the followed member") { expect(@member1.followed).not_to include(@member2) }
      it("no longer lists the follower") { expect(@member2.followers).not_to include(@member1) }
    end
  end
end
