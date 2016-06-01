require 'rails_helper'

describe SeedTrade do

  let(:seed_trade) { FactoryGirl.build(:seed_trade) }

  it "belongs to a requester" do
    expect(seed_trade.requester).to be_an_instance_of Member
  end

  it "belongs to a seed" do
    expect(seed_trade.seed).to be_an_instance_of Seed
  end

  it "has a message" do
    seed_trade.message = nil
    expect(seed_trade).not_to be_valid
    seed_trade.message = "       "
    expect(seed_trade).not_to be_valid
  end

  it "has an address" do
    seed_trade.address = nil
    expect(seed_trade).not_to be_valid
    seed_trade.address = "       "
    expect(seed_trade).not_to be_valid
  end

  it "shows if is replied" do
    expect(seed_trade.replied?).to be_falsy
    accepted_seed_trade = FactoryGirl.build(:accepted_seed_trade)
    expect(accepted_seed_trade.replied?).to be_truthy
    declined_seed_trade = FactoryGirl.build(:declined_seed_trade)
    expect(accepted_seed_trade.replied?).to be_truthy
  end

  it "filter by member being requester" do
    requester   = FactoryGirl.create(:member)
    seed_trade1 = FactoryGirl.create(:seed_trade, requester: requester)
    seed_trade2 = FactoryGirl.create(:seed_trade, requester: nil)
    expect(SeedTrade.by_member(requester).size).to eq 1
    seed_trade2.update(requester: requester)
    expect(SeedTrade.by_member(requester).size).to eq 2
  end

  it "filter by member being seed owner" do
    tradable_seed  = FactoryGirl.create(:tradable_seed)
    seed_trade1    = FactoryGirl.create(:seed_trade, seed: tradable_seed)
    seed_trade2    = FactoryGirl.create(:seed_trade, seed: nil)
    expect(SeedTrade.by_member(tradable_seed.owner).size).to eq 1
    seed_trade2.update(seed: tradable_seed)
    expect(SeedTrade.by_member(tradable_seed.owner).size).to eq 2
  end

  it "shows the 'Requested' status" do
    seed_trade = FactoryGirl.build(:seed_trade)
    expect(seed_trade.status).to eq "Requested"
  end

  it "shows the 'Accepted' status" do
    accepted_seed_trade = FactoryGirl.build(:accepted_seed_trade)
    expect(accepted_seed_trade.status).to eq "Accepted"
  end

  it "shows the 'Declined' status" do
    declined_seed_trade = FactoryGirl.build(:declined_seed_trade)
    expect(declined_seed_trade.status).to eq "Declined"
  end

  it "shows the 'Sent' status" do
    sent_seed_trade     = FactoryGirl.build(:sent_seed_trade)
    expect(sent_seed_trade.status).to eq "Sent"
  end

  it "shows the 'Received' status" do
    received_seed_trade = FactoryGirl.build(:received_seed_trade)
    expect(received_seed_trade.status).to eq "Received"
  end

  it "is aways ordered by date" do
    @old = FactoryGirl.create(:seed_trade, created_at: 2.days.ago)
    @new = FactoryGirl.create(:seed_trade, created_at: Time.zone.now)

    expect(SeedTrade.first).to eq @new
  end
end
