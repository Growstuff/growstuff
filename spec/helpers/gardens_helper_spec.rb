# frozen_string_literal: true

require 'rails_helper'

describe GardensHelper do
  describe "garden description" do
    it "is missing" do
      garden = create(:garden,
                      description: nil)
      result = helper.display_garden_description(garden)
      expect(result).to eq "no description provided."
    end

    it "is less than 130 characters long" do
      garden = create(:garden,
                      description: 'a' * 20)
      result = helper.display_garden_description(garden)
      expect(result).to eq 'a' * 20
    end

    it "is 130 characters long" do
      garden = create(:garden,
                      description: 'a' * 130)
      result = helper.display_garden_description(garden)
      expect(result).to eq 'a' * 130
    end

    it "is more than 130 characters long" do
      garden = create(:garden,
                      description: 'a' * 140)
      result = helper.display_garden_description(garden)
      expect(result).to eq ('a' * 126) + '...' + ' ' + link_to("Read more", garden_path(garden))
    end
  end

  describe "garden plantings" do
    it "is missing" do
      result = helper.display_garden_plantings(nil)
      expect(result).to eq "None"
    end

    it "has 1 planting" do
      crop = create(:crop)
      plantings = [create(:planting, quantity: 10, crop:)]
      result = helper.display_garden_plantings(plantings)

      output = '<ul class="plantings"><li>'
      output += "10 " + link_to(crop.name, crop)
      output += ", planted on #{plantings.first.planted_at}"
      output += "</li></ul>"
      expect(result).to eq output
    end

    it "has 2 plantings" do
      plantings = []

      crop1 = create(:crop)
      plantings << create(:planting, quantity: 10, crop: crop1)

      crop2 = create(:crop)
      plantings << create(:planting, quantity: 10, crop: crop2)

      result = helper.display_garden_plantings(plantings.first(2))

      output = '<ul class="plantings"><li>'
      output += "10 " + link_to(crop1.name, crop1)
      output += ", planted on #{plantings.first.planted_at}"
      output += "</li>"
      output += "<li>"
      output += "10 " + link_to(crop2.name, crop2)
      output += ", planted on #{plantings.first.planted_at}"
      output += "</li></ul>"
      expect(result).to eq output
    end

    it "has 3 plantings" do
      plantings = []

      crop1 = create(:crop)
      plantings << create(:planting, quantity: 10, crop: crop1)

      crop2 = create(:crop)
      plantings << create(:planting, quantity: 10, crop: crop2)

      crop3 = create(:crop)
      plantings << create(:planting, quantity: 10, crop: crop3)

      result = helper.display_garden_plantings(plantings.first(2))

      output = '<ul class="plantings"><li>'
      output += "10 " + link_to(crop1.name, crop1)
      output += ", planted on #{plantings.first.planted_at}"
      output += "</li>"
      output += "<li>"
      output += "10 " + link_to(crop2.name, crop2)
      output += ", planted on #{plantings.first.planted_at}"
      output += "</li></ul>"
      expect(result).to eq output
    end
  end

  describe '#garden_distance' do
    subject(:distance) { helper.garden_distance(garden) }

    let(:viewer) { build_stubbed(:member, latitude: -41.29, longitude: 174.78) }
    let(:garden) { build_stubbed(:garden, latitude: -36.85, longitude: 174.76) }

    before { allow(helper).to receive(:current_member).and_return(viewer) }

    context 'when both have a location' do
      it { is_expected.to match(/\Aabout \d+ km from you\z/) }
    end

    context 'when the garden has no location' do
      let(:garden) { build_stubbed(:garden, latitude: nil, longitude: nil) }

      it { is_expected.to be_nil }
    end

    context 'when the viewer owns the garden' do
      let(:garden) { build_stubbed(:garden, owner: viewer, latitude: -36.85, longitude: 174.76) }

      it { is_expected.to be_nil }
    end

    context 'when nobody is signed in' do
      let(:viewer) { nil }

      it { is_expected.to be_nil }
    end
  end
end
