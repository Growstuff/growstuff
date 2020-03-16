# frozen_string_literal: true

require 'rails_helper'

describe GardensHelper do
  describe "garden description" do
    it "is missing" do
      garden = FactoryBot.create(:garden,
                                 description: nil)
      result = helper.display_garden_description(garden)
      expect(result).to eq "no description provided."
    end

    it "is less than 130 characters long" do
      garden = FactoryBot.create(:garden,
                                 description: 'a' * 20)
      result = helper.display_garden_description(garden)
      expect(result).to eq 'a' * 20
    end

    it "is 130 characters long" do
      garden = FactoryBot.create(:garden,
                                 description: 'a' * 130)
      result = helper.display_garden_description(garden)
      expect(result).to eq 'a' * 130
    end

    it "is more than 130 characters long" do
      garden = FactoryBot.create(:garden,
                                 description: 'a' * 140)
      result = helper.display_garden_description(garden)
      expect(result).to eq 'a' * 126 + '...' + ' ' + link_to("Read more", garden_path(garden))
    end
  end

  describe "garden plantings" do
    it "is missing" do
      result = helper.display_garden_plantings(nil)
      expect(result).to eq "None"
    end

    it "has 1 planting" do
      crop = FactoryBot.create(:crop)
      plantings = [FactoryBot.create(:planting, quantity: 10, crop: crop)]
      result = helper.display_garden_plantings(plantings)

      output = '<ul class="plantings"><li>'
      output += "10 " + link_to(crop.name, crop)
      output += ", planted on #{plantings.first.planted_at}"
      output += "</li></ul>"
      expect(result).to eq output
    end

    it "has 2 plantings" do
      plantings = []

      crop1 = FactoryBot.create(:crop)
      plantings << FactoryBot.create(:planting, quantity: 10, crop: crop1)

      crop2 = FactoryBot.create(:crop)
      plantings << FactoryBot.create(:planting, quantity: 10, crop: crop2)

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

      crop1 = FactoryBot.create(:crop)
      plantings << FactoryBot.create(:planting, quantity: 10, crop: crop1)

      crop2 = FactoryBot.create(:crop)
      plantings << FactoryBot.create(:planting, quantity: 10, crop: crop2)

      crop3 = FactoryBot.create(:crop)
      plantings << FactoryBot.create(:planting, quantity: 10, crop: crop3)

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
end
