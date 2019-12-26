# frozen_string_literal: true

require 'rails_helper'

describe "browse crops" do
  let(:tomato) { FactoryBot.create :tomato }

  it "Show crop info" do
    visit crop_path(tomato)
    expect(page).to have_text 'tomato'
  end

  describe "shows varieties" do
    let!(:cherry) { FactoryBot.create :crop, name: 'cherry tomato', parent: tomato }
    let!(:heirloom) { FactoryBot.create :crop, name: 'heirloom tomato', parent: tomato }
    let!(:striped) { FactoryBot.create :crop, name: 'striped tomato', parent: heirloom }
    before { visit crop_path(tomato) }
    it { expect(page).to have_link heirloom.name, href: crop_path(heirloom) }
    it { expect(page).to have_link cherry.name, href: crop_path(cherry) }
    it { expect(page).to have_link striped.name, href: crop_path(striped) }
  end

  context "when the most recently created harvest is not the most recently harvested" do
    before { FactoryBot.create_list :harvest, 20, crop: tomato, harvested_at: 1.year.ago, created_at: 1.minute.ago }

    let!(:most_recent_harvest) do
      FactoryBot.create :harvest, crop: tomato, harvested_at: 60.minutes.ago, created_at: 10.minutes.ago
    end

    it "Shows most recently harvested harvest" do
      visit crop_path(tomato)
      expect(page).to have_link(href: harvest_path(most_recent_harvest))
    end
  end

  context "when the most recently created planting is not the most recently planted" do
    before { FactoryBot.create_list :planting, 20, crop: tomato, planted_at: 1.year.ago, created_at: 1.minute.ago }

    let!(:most_recent_planting) do
      FactoryBot.create :planting, crop: tomato, planted_at: 60.minutes.ago, created_at: 10.minutes.ago
    end

    it "Shows most recently planted planting" do
      visit crop_path(tomato)
      expect(page).to have_link(href: planting_path(most_recent_planting))
    end
  end
end
