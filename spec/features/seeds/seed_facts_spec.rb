# frozen_string_literal: true

require 'rails_helper'

describe "a seed's facts", :js do
  let(:seed) { create(:seed, owner:, heirloom: 'unknown') }
  let(:owner) { create(:member) }
  let(:fact) { find('.fact-row', text: 'Heirloom or hybrid') }

  describe "the heirloom or hybrid fact" do
    context "when signed in as the owner" do
      before do
        login_as owner
        visit seed_path(seed)
        fact.click_link 'Edit heirloom'
        fact.select 'hybrid'
        fact.click_button 'save'
        find('.seedfacts--heirloom', text: 'Hybrid') # saved, and the page shows it
      end

      it { expect(page).to have_css('.seedfacts--heirloom', text: 'Hybrid') }
      it { expect(seed.reload.heirloom).to eq 'hybrid' }
    end

    context "when signed in as someone else" do
      before do
        login_as create(:member)
        visit seed_path(seed)
      end

      it { expect(page).to have_css('.seedfacts--heirloom', text: 'Unknown') }
      it { expect(page).to have_no_link('Edit heirloom') }
    end
  end

  describe "the organic fact" do
    let(:seed) { create(:seed, owner:, organic: 'unknown') }
    let(:organic) { find('.fact-row', text: 'Organic') }

    before do
      login_as owner
      visit seed_path(seed)
      organic.click_link 'Edit organic'
      organic.select 'certified organic'
      organic.click_button 'save'
      find('.seedfacts--organic', text: 'Certified organic') # saved, and the page shows it
    end

    it { expect(page).to have_css('.seedfacts--organic', text: 'Certified organic') }
    it { expect(seed.reload.organic).to eq 'certified organic' }
  end

  describe "when to sow" do
    let(:owner) { create_located_member('Sowing spec southern town', -41.3, 174.8) }
    let(:seed) { create(:seed, owner:, sow_months: []) }
    let(:fact) { find('.fact-row', text: 'When to sow') }

    before do
      login_as owner
      visit seed_path(seed)
      fact.click_link 'Edit sow months'
      fact.click_button 'Spring' # the southern spring: September to November
      fact.click_button 'save'
      find('.seedfacts--sowmonths', text: 'Sep–Nov') # saved, and the page shows it
    end

    it { expect(page).to have_css('.seedfacts--sowmonths', text: 'Sep–Nov') }
    it { expect(seed.reload.sow_months).to eq [9, 10, 11] }
  end
end
