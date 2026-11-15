# frozen_string_literal: true

require 'rails_helper'

describe PlantingsController, flipper: :planting_codes do
  let(:planting) { create(:planting) }
  let(:owner) { planting.owner }
  let(:page) { Capybara.string(response.body) }

  context 'when viewing your own member plantings list' do
    before do
      sign_in owner
      get member_plantings_path(owner)
    end

    it 'shows the planting short code' do
      expect(page).to have_css('.card.planting .planting-short-code', text: planting.short_code)
    end
  end

  context 'when viewing another member’s plantings list' do
    before do
      sign_in create(:member)
      get member_plantings_path(owner)
    end

    it 'does not show short codes' do
      expect(page).to have_no_css('.planting-short-code')
    end
  end

  context 'when viewing a member’s plantings list without signing in' do
    before { get member_plantings_path(owner) }

    it 'does not show short codes' do
      expect(page).to have_no_css('.planting-short-code')
    end
  end

  context 'when viewing the general plantings list as an owner' do
    before do
      sign_in owner
      get plantings_path
    end

    it 'shows your planting code' do
      expect(page).to have_css('.planting-short-code', text: planting.short_code)
    end
  end

  context 'when collaborating in the planting garden' do
    let(:collaborator) { create(:garden_collaborator, garden: planting.garden).member }

    before { sign_in collaborator }

    it 'shows the code on the member list' do
      get member_plantings_path(owner)
      expect(page).to have_css('.planting-short-code', text: planting.short_code)
    end
  end

  describe '#show' do
    shared_examples 'a visible code' do
      it 'shows the header code' do
        get planting_path(planting)
        expect(page).to have_css('.planting-short-code', text: planting.short_code)
      end

      it 'shows the facts code' do
        get planting_path(planting)
        expect(page).to have_css('.plantingfact--shortcode', text: planting.short_code)
      end
    end

    context 'when signed in as the owner' do
      before { sign_in owner }

      it_behaves_like 'a visible code'
    end

    context 'when signed in as a collaborator' do
      before { sign_in create(:garden_collaborator, garden: planting.garden).member }

      it_behaves_like 'a visible code'
    end

    context 'when signed in as another member' do
      before { sign_in create(:member) }

      it 'hides both codes' do
        get planting_path(planting)
        expect(page).to have_no_css('.planting-short-code, .plantingfact--shortcode')
      end
    end
  end

  context 'when the feature is disabled', flipper: [] do
    before { sign_in owner }

    it 'hides codes on the owner list' do
      get member_plantings_path(owner)
      expect(page).to have_no_css('.planting-short-code')
    end

    it 'hides both codes on the planting page' do
      get planting_path(planting)
      expect(page).to have_no_css('.planting-short-code, .plantingfact--shortcode')
    end

    context 'with a feature grant for the owner' do
      before { Flipper.enable_actor(:planting_codes, owner) }

      it 'shows the owner code' do
        get planting_path(planting)
        expect(page).to have_css('.planting-short-code', text: planting.short_code)
      end
    end
  end
end
