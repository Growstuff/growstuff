# frozen_string_literal: true

require 'rails_helper'

describe GardenType do
  let(:garden) { create(:garden, 'Free Carrots') }

  describe "should have a name" do
    let(:garden_type) { build(:garden_type, name: "organic") }

    it { expect(garden_type).to be_valid }
  end

  describe "doesn't allow a nil name" do
    let(:garden_type) { build(:garden_type, name: nil) }

    it { expect(garden_type).not_to be_valid }
  end

  describe "doesn't allow a blank name" do
    let(:garden_type) { build(:garden_type, name: "") }

    it { expect(garden_type).not_to be_valid }
  end

  describe "doesn't allow a name with only spaces" do
    let(:garden_type) { build(:garden_type, name: "    ") }

    it { expect(garden_type).not_to be_valid }
  end

  describe "does not delete gardens when deleted" do
    before { create(:garden, garden_type:) }

    let(:garden_type) { create(:garden_type, name: "Massive Flower Pot") }

    it { expect(garden_type.gardens.size).to eq(1) }
    it { expect { garden_type.destroy }.not_to change(Garden, :count) }
  end

  describe "#subtitler" do
    let(:garden_type) { create(:garden_type, name: "Community Plot") }

    context "when there are no gardens" do
      it "returns 0 gardens string" do
        expect(garden_type.subtitler).to eq("0 gardens are using this garden type")
      end
    end

    context "when there is 1 garden" do
      before { create(:garden, garden_type:) }

      it "returns 1 garden string" do
        expect(garden_type.subtitler).to eq("1 garden is using this garden type")
      end
    end

    context "when there are multiple gardens" do
      before do
        create(:garden, garden_type:)
        create(:garden, garden_type:)
      end

      it "returns plural gardens string" do
        expect(garden_type.subtitler).to eq("2 gardens are using this garden type")
      end
    end
  end
end
