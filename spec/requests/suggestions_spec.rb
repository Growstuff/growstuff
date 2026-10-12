# frozen_string_literal: true

require 'rails_helper'

# The page of every crop to sow this month, and the switch for turning
# suggestions off.
describe 'Crop suggestions' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }

  context 'when signed in' do
    before { sign_in member }

    it 'turns suggestions off' do
      patch my_suggestions_path, params: { suggest: false }
      expect(member.reload.suggest_crops).to be false
    end

    it 'turns suggestions back on' do
      member.update_columns(suggest_crops: false)
      patch my_suggestions_path, params: { suggest: true }
      expect(member.reload.suggest_crops).to be true
    end

    it 'says so when suggestions are turned off' do
      patch my_suggestions_path, params: { suggest: false }
      expect(flash[:notice]).to eq "We've stopped suggesting crops."
    end

    it 'asks for a location before suggesting anything' do
      get suggestions_path
      expect(response.body).to include 'Tell us where you garden and we can suggest what to sow.'
    end

    it 'lists the month in the title' do
      member.update_columns(latitude: -41.3, longitude: 174.7)
      get suggestions_path
      expect(response.body).to include "Easy to sow in #{I18n.l(Time.zone.today, format: '%B')} near you"
    end

    it 'says suggestions are off when they are' do
      member.update_columns(latitude: -41.3, longitude: 174.7, suggest_crops: false)
      get suggestions_path
      expect(response.body).to include 'Crop suggestions are off.'
    end
  end

  context 'when signed out' do
    it 'does not show the page' do
      get suggestions_path
      expect(response).to redirect_to new_member_session_path
    end
  end
end
