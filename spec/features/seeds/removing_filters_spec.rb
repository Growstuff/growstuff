# frozen_string_literal: true

require 'rails_helper'

describe "removing seed library filters", :js do
  include_context 'signed in member'

  let(:tomato) { create(:crop, name: 'tomato') }
  let(:cherry) { create(:crop, name: 'cherry tomato', parent: tomato) }
  let(:kale) { create(:crop, name: 'kale') }

  before do
    create(:seed, owner: member, crop: tomato, source: 'retail outlet', heirloom: 'heirloom', sow_months: [9])
    create(:seed, owner: member, crop: kale, source: 'my own seed saving', heirloom: 'hybrid', sow_months: [3])
    visit member_seeds_path(member, from: 'retail', heirloom: 'heirloom', planted: 'no', sow_month: 9, crop: tomato.slug, group: 'year')
    find('.seed-chip.active', text: 'Retail outlet')
  end

  context "when choosing all" do
    before { click_link 'All' }

    it { expect(page).to have_seed_params(heirloom: 'heirloom', planted: 'no', sow_month: 9, crop: tomato.slug, group: 'year') }
    it { expect(page).to have_css('.seed-chip.active', text: 'All') }
  end

  context "when choosing any planting" do
    before { click_link 'Any' }

    it { expect(page).to have_seed_params(from: 'retail', heirloom: 'heirloom', sow_month: 9, crop: tomato.slug, group: 'year') }
  end

  context "when clearing the crop" do
    before { click_link 'Clear crop' }

    it { expect(page).to have_seed_params(from: 'retail', heirloom: 'heirloom', planted: 'no', sow_month: 9, group: 'year') }
  end

  context "when choosing any sowing month" do
    before { select 'Any month', from: 'Month to sow' }

    it { expect(page).to have_seed_params(from: 'retail', heirloom: 'heirloom', planted: 'no', crop: tomato.slug, group: 'year') }
  end

  context "when choosing a chosen chip again" do
    before { click_link 'Heirloom only' }

    it { expect(page).to have_seed_params(from: 'retail', planted: 'no', sow_month: 9, crop: tomato.slug, group: 'year') }
  end

  context "when clearing all filters" do
    before { click_link 'Clear all filters' }

    it { expect(page).to have_seed_params(group: 'year') }
  end

  context "when everything is cleared" do
    before { click_link 'Clear all filters' }

    it { expect(page).to have_no_link('Clear all filters') }
  end
end
