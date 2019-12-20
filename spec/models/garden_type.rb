# frozen_string_literal: true

require 'rails_helper'

describe GardenType do
  let(:garden) { FactoryBot.create(:garden, 'Free Carrots') }

  describe "should have a name" do
    let(:garden_type) { FactoryBot.build(:garden_type, name: "organic") }

    it { expect(garden_type).to be_valid }
  end

  describe "doesn't allow a nil name" do
    let(:garden_type) { FactoryBot.build(:garden_type, name: nil) }

    it { expect(garden_type).not_to be_valid }
  end

  describe "doesn't allow a blank name" do
    let(:garden_type) { FactoryBot.build(:garden_type, name: "") }

    it { expect(garden_type).not_to be_valid }
  end

  describe "doesn't allow a name with only spaces" do
    let(:garden_type) { FactoryBot.build(:garden_type, name: "    ") }

    it { expect(garden_type).not_to be_valid }
  end

  describe "does not delete gardens when deleted" do
    before { FactoryBot.create :garden, garden_type: garden_type }

    let(:garden_type) { FactoryBot.create(:garden_type, name: "Massive Flower Pot") }

    it { expect(garden_type.gardens.size).to eq(1) }
    it { expect { garden_type.destroy }.not_to change(Garden, :count) }
  end
end
