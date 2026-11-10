# frozen_string_literal: true

require "rails_helper"
require 'custom_matchers'

describe "Display a planting", :js do
  context 'when anonymous' do
    before { visit planting_path(planting) }

    context 'with a perennial planted long ago' do
      let(:planting) { create(:perennial_planting) }

      it { expect(page).to have_text 'Perennial' }
    end

    context 'with a finished perennial' do
      let(:planting) { create(:perennial_planting, planted_at: 6.years.ago, finished: true, finished_at: 1.year.ago) }

      it { expect(page).to have_text 'Perennial' }
    end

    context 'with an annual and no predictions' do
      let(:planting) { create(:annual_planting) }

      it { expect(page).to have_no_text 'Finish expected' }
    end

    context 'with an annual with a predicted finish' do
      let(:planting) { create(:predictable_planting, planted_at: 2.weeks.ago) }

      it { expect(page).to have_text '28%' }
      it { expect(page).to have_text 'day 14 of 50' }
      it { expect(page).to have_text "Planted #{I18n.l(2.weeks.ago.to_date)}" }
      it { expect(page).to have_text 'Finish expected' }
    end

    context 'with a finished annual' do
      let(:planting) { create(:annual_planting, planted_at: 100.days.ago, finished: true, finished_at: 1.day.ago) }

      it { expect(page).to have_text "Planted #{I18n.l(planting.planted_at)}" }
    end

    context 'with a planting with harvests' do
      let(:planting) { create(:harvest_with_planting).planting }

      it { expect(page).to have_text 'Harvest started' }
    end

    context 'with a planting whose harvest is predictable' do
      let(:planting) do
        crop = create(:annual_crop)
        # 50 days to harvest
        create(:harvest, harvested_at: 150.days.ago, crop:,
                                    planting: create(:planting, planted_at: 200.days.ago, crop:))
        # 20 days to harvest
        create(:harvest, harvested_at: 180.days.ago, crop:,
                                    planting: create(:planting, planted_at: 200.days.ago, crop:))
        # 10 days to harvest
        create(:harvest, harvested_at: 190.days.ago, crop:,
                                    planting: create(:planting, planted_at: 200.days.ago, crop:))
        crop.update_medians

        create(:annual_planting, planted_at: 200.days.ago, crop:)
      end

      it { expect(page).to have_text 'First harvest expected' }
    end

    context 'with quantity' do
      let(:planting) { create(:planting, quantity: 100) }

      it { expect(find('.plantingfact--quantity')).to have_text '100' }
    end
  end

  context 'when signed in' do
    include_context 'signed in member'
    before { visit planting_path(planting) }

    context 'when it has no record of how it was started' do
      let(:seed) { create(:seed, saved_at: 1.month.ago, owner: member) }
      let(:planting) { create(:planting, planted_at: 1.day.ago, crop: seed.crop, owner: member) }

      it { expect(page).to have_css '.origin-unanswered' }

      describe 'linking a packet' do
        before do
          click_button I18n.t('plantings.origin.link_a_seed')
          click_button 'Seed', match: :first
          click_button I18n.t('plantings.origin.dialog.choose')
        end

        # The parent seed links to the seed. The breadcrumb used to link
        # to this planting, but the last crumb is the page you are on, so it
        # is plain text now.
        it { expect(page).to have_link href: seed_path(seed) }
      end
    end
  end
end
