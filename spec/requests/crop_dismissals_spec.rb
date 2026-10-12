# frozen_string_literal: true

require 'rails_helper'

# "Not for me" on a suggested crop on the home page.
describe 'Dismissing a suggested crop' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:crop) { create(:crop, name: 'persian lime') }

  context 'when signed in' do
    before { sign_in member }

    it 'remembers the crop is not for them' do
      post crop_dismissals_path, params: { crop_id: crop.id }
      expect(member.dismissed_crops).to eq [crop]
    end

    it 'does not mind being told twice' do
      2.times { post crop_dismissals_path, params: { crop_id: crop.id } }
      expect(member.crop_dismissals.count).to eq 1
    end

    it 'says it will not suggest the crop again' do
      post crop_dismissals_path, params: { crop_id: crop.id }
      expect(flash[:notice]).to eq "We won't suggest persian lime again."
    end

    it 'does not take a crop that is not approved' do
      pending_crop = create(:crop, approval_status: 'pending')
      post crop_dismissals_path, params: { crop_id: pending_crop.id }
      expect(response).to have_http_status(:not_found)
    end

    it 'brings every hidden suggestion back' do
      create(:crop_dismissal, member:, crop:)
      delete '/my/dismissed_crops'
      expect(member.crop_dismissals.count).to eq 0
    end

    it 'leaves other members\' dismissals alone' do
      create(:crop_dismissal, crop:)
      delete '/my/dismissed_crops'
      expect(CropDismissal.count).to eq 1
    end
  end

  context 'when signed out' do
    it 'does not record anything' do
      post crop_dismissals_path, params: { crop_id: crop.id }
      expect(CropDismissal.count).to eq 0
    end
  end
end
