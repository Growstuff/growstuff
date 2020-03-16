# frozen_string_literal: true

require "rails_helper"
require 'custom_matchers'
describe "Display a planting", :js do
  describe 'planting perennial' do
    let(:garden) { FactoryBot.create :garden, location: 'Edinburgh' }
    let(:crop) { FactoryBot.create(:crop, name: 'feijoa', perennial: true) }
    let(:planting) { FactoryBot.create :planting, crop: crop, garden: garden, owner: garden.owner }

    describe 'no harvest to predict from' do
      before { visit planting_path(planting) }
      it { expect(planting.harvest_months).to eq({}) }
      it { expect(page).to have_content 'We need more data on this crop in your latitude.' }
    end

    describe 'harvests used to predict' do
      before do
        FactoryBot.create :harvest, planting: planting, crop: crop, harvested_at: '1 May 2019'
        FactoryBot.create :harvest, planting: planting, crop: crop, harvested_at: '18 June 2019'
        FactoryBot.create_list :harvest, 4, planting: planting, crop: crop, harvested_at: '18 August 2019'
      end
      before { visit planting_path(planting) }
      it { expect(page.find("#month-1")[:class]).not_to include("badge-harvesting") }
      it { expect(page.find("#month-2")[:class]).not_to include("badge-harvesting") }
      it { expect(page.find("#month-5")[:class]).to include("badge-harvesting") }
      it { expect(page.find("#month-6")[:class]).to include("badge-harvesting") }
      it { expect(page.find("#month-8")[:class]).to include("badge-harvesting") }
    end

    describe 'nearby plantings used to predict' do
      # Note the locations used need to be stubbed in geocoder

      before do
        # Near by planting with harvests
        nearby_garden = FactoryBot.create :garden, location: 'Greenwich, UK'
        nearby_planting = FactoryBot.create :planting, crop: crop,
                                                       garden: nearby_garden, owner: nearby_garden.owner, planted_at: '1 January 2000'
        FactoryBot.create :harvest, planting: nearby_planting, crop: crop,
                                    harvested_at: '1 May 2019'
        FactoryBot.create :harvest, planting: nearby_planting, crop: crop,
                                    harvested_at: '18 June 2019'
        FactoryBot.create_list :harvest, 4, planting: nearby_planting, crop: crop,
                                            harvested_at: '18 August 2008'

        # far away planting harvests
        faraway_garden = FactoryBot.create :garden, location: 'Amundsen-Scott Base, Antarctica'
        faraway_planting = FactoryBot.create :planting, garden: faraway_garden, crop: crop,
                                                        owner: faraway_garden.owner, planted_at: '16 May 2001'

        FactoryBot.create_list :harvest, 4, planting: faraway_planting, crop: crop,
                                            harvested_at: '18 December 2006'
      end
      before { visit planting_path(planting) }
      it { expect(page.find("#month-1")[:class]).not_to include("badge-harvesting") }
      it { expect(page.find("#month-2")[:class]).not_to include("badge-harvesting") }
      it { expect(page.find("#month-5")[:class]).to include("badge-harvesting") }
      it { expect(page.find("#month-6")[:class]).to include("badge-harvesting") }
      it { expect(page.find("#month-8")[:class]).to include("badge-harvesting") }
    end
  end
end
