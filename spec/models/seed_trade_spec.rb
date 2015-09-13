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
    seed_trade.message = ''
    expect(seed_trade).not_to be_valid
  end

  it "has an address" do
    seed_trade.address = nil
    expect(seed_trade).not_to be_valid
    seed_trade.address = ''
    expect(seed_trade).not_to be_valid
  end

  it "is aways ordered by date" do
    @old = FactoryGirl.create(:seed_trade, created_at: 1.day.ago)
    @new = FactoryGirl.create(:seed_trade)

    expect(SeedTrade.first).to eq @new
  end
end
