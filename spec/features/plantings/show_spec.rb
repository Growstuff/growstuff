# frozen_string_literal: true

require "rails_helper"
require 'custom_matchers'

describe "Display a planting", :js do
  context 'anonymous' do
    before { visit planting_path(planting) }

    context 'Perennial planted long ago' do
      let(:planting) { FactoryBot.create :perennial_planting }
      it { expect(page).to have_text 'Perennial' }
    end

    context 'Perennial finished' do
      let(:planting) { FactoryBot.create :perennial_planting, planted_at: 6.years.ago, finished: true, finished_at: 1.year.ago }
      it { expect(page).to have_text 'Perennial' }
    end

    context 'Annual no predictions' do
      let(:planting) { FactoryBot.create :annual_planting }
      it { expect(page).not_to have_text 'Finish expected' }
    end

    context 'Annual with predicted finish' do
      let(:planting) { FactoryBot.create :predicatable_planting, planted_at: 2.weeks.ago }
      it { expect(page).to have_text '28%' }
      it { expect(page).to have_text '14/50 days' }
      it { expect(page).to have_text "Planted #{I18n.l(2.weeks.ago.to_date)}" }
      it { expect(page).to have_text 'Finish expected' }
    end

    context 'Annual finished' do
      let(:planting) { FactoryBot.create :annual_planting, planted_at: 100.days.ago, finished: true, finished_at: 1.day.ago }
      it { expect(page).to have_text "Planted #{I18n.l(planting.planted_at)}" }
    end

    context 'Planting with harvests' do
      let(:planting) { FactoryBot.create(:harvest_with_planting).planting }
      it { expect(page).to have_text 'Harvest started' }
    end

    context 'Planting with harvest predictable' do
      let(:planting) do
        crop = FactoryBot.create :annual_crop
        # 50 days to harvest
        FactoryBot.create(:harvest, harvested_at: 150.days.ago, crop: crop,
                                    planting: FactoryBot.create(:planting, planted_at: 200.days.ago, crop: crop))
        # 20 days to harvest
        FactoryBot.create(:harvest, harvested_at: 180.days.ago, crop: crop,
                                    planting: FactoryBot.create(:planting, planted_at: 200.days.ago, crop: crop))
        # 10 days to harvest
        FactoryBot.create(:harvest, harvested_at: 190.days.ago, crop: crop,
                                    planting: FactoryBot.create(:planting, planted_at: 200.days.ago, crop: crop))
        crop.update_medians

        FactoryBot.create :annual_planting, planted_at: 200.days.ago, crop: crop
      end
      it { expect(page).to have_text 'First harvest expected' }
    end

    context 'with quantity' do
      let(:planting) { FactoryBot.create :planting, quantity: 100 }
      it { expect(find('.plantingfact--quantity')).to have_text '100' }
    end
  end

  context 'signed in' do
    include_context 'signed in member'
    before { visit planting_path(planting) }

    context 'with matching seeds' do
      let(:seed) { FactoryBot.create :seed, saved_at: 1.month.ago, owner: member }
      let(:planting) { FactoryBot.create :planting, planted_at: 1.day.ago, crop: seed.crop, owner: member }
      it { expect(page).to have_text 'Is this from one of these plantings? ' }
      describe 'linking to planting' do
        before do
          choose "planting_parent_seed_id_#{planting.id}"
          click_button 'save'
        end
        it { expect(page).to have_text 'Parent seed' }
        it { expect(page).to have_link href: planting_path(planting) }
      end
    end
  end
end
