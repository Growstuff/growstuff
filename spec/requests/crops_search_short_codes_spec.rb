# frozen_string_literal: true

require 'rails_helper'

describe CropsController, '#search' do
  let(:planting) { create(:planting, short_code: 'A2B3') }

  context 'when signed in' do
    before { sign_in planting.owner }

    it 'redirects an exact short code to your planting' do
      get search_crops_path, params: { term: planting.short_code }

      expect(response).to redirect_to(planting_path(planting))
    end

    it 'finds finished plantings by short code' do
      planting.update!(finished: true)
      get search_crops_path, params: { term: planting.short_code }

      expect(response).to redirect_to(planting_path(planting))
    end

    it 'continues crop search for an unmatched code' do
      get search_crops_path, params: { term: 'WXYZ' }

      expect(response).to have_http_status(:ok)
    end

    it 'does not match part of a short code' do
      get search_crops_path, params: { term: 'A2B' }

      expect(response).to have_http_status(:ok)
    end

    it 'does not redirect JSON autocomplete' do
      get search_crops_path(format: :json), params: { term: planting.short_code }

      expect(response).to have_http_status(:ok)
    end

    context 'with the same code belonging to another member' do
      let(:other_planting) { create(:planting, short_code: planting.short_code) }

      it 'still redirects to your own planting' do
        other_planting
        get search_crops_path, params: { term: planting.short_code }

        expect(response).to redirect_to(planting_path(planting))
      end
    end
  end

  context 'when signed in as another member' do
    before { sign_in create(:member) }

    it 'does not redirect to someone else’s planting' do
      get search_crops_path, params: { term: planting.short_code }

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when signed out' do
    it 'continues crop search' do
      get search_crops_path, params: { term: planting.short_code }

      expect(response).to have_http_status(:ok)
    end
  end
end
