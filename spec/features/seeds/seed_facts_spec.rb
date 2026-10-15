# frozen_string_literal: true

require 'rails_helper'

describe "a seed's facts", :js do
  let(:seed) { create(:seed, owner:, heirloom: 'unknown') }
  let(:owner) { create(:member) }
  let(:fact) { find('.card', text: 'Heirloom or hybrid') }

  describe "the heirloom or hybrid fact" do
    context "when signed in as the owner" do
      before do
        login_as owner
        visit seed_path(seed)
        fact.click_link 'Edit heirloom'
        fact.select 'hybrid'
        fact.click_button 'save'
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
end
