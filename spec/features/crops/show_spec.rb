require 'rails_helper'

feature "browse crops" do
  let(:tomato) { create :tomato }
  let(:maize)  { create :maize }
  let(:pending_crop) { create :crop_request }
  let(:rejected_crop)  { create :rejected_crop }

  scenario "Show crop info" do
    visit crop_path(tomato)
    expect(page).to have_text 'tomato'
  end

  context "when the most recently created harvest is not the most recently harvested" do
    before { FactoryBot.create_list :harvest, 20, crop: tomato, harvested_at: 1.year.ago, created_at: 1.minute.ago }

    let!(:most_recent_harvest) do
      FactoryBot.create :harvest, crop: tomato, harvested_at: 60.minutes.ago, created_at: 10.minute.ago
    end

    scenario "Shows most recently harvested harvest" do
      visit crop_path(tomato)
      expect(page).to have_link(href: harvest_path(most_recent_harvest))
    end
  end

  context "when the most recently created planting is not the most recently planted" do
    before { FactoryBot.create_list :planting, 20, crop: tomato, planted_at: 1.year.ago, created_at: 1.minute.ago }

    let!(:most_recent_planting) do
      FactoryBot.create :planting, crop: tomato, planted_at: 60.minutes.ago, created_at: 10.minute.ago
    end

    scenario "Shows most recently planted planting" do
      visit crop_path(tomato)
      expect(page).to have_link(href: planting_path(most_recent_planting))
    end
  end
end
