# frozen_string_literal: true

require 'rails_helper'

describe 'Searching for a seed packet code' do
  let(:seed) { create(:seed, short_code: 'O2B3') }

  context 'when signed in as the owner' do
    before { sign_in seed.owner }

    it 'redirects the code to the packet' do
      get search_crops_path, params: { term: seed.short_code }

      expect(response).to redirect_to(seed_path(slug: seed.slug))
    end

    it 'does not redirect JSON autocomplete' do
      get search_crops_path(format: :json), params: { term: seed.short_code }

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when signed in as another member' do
    before { sign_in create(:member) }

    it 'does not redirect to someone else’s packet' do
      get search_crops_path, params: { term: seed.short_code }

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when the planting and the packet share a code' do
    let(:planting) { create(:planting, owner: seed.owner, garden: create(:garden, owner: seed.owner), short_code: 'T2B3') }

    before do
      seed.update!(short_code: 'T2B3')
      sign_in seed.owner
      get search_crops_path, params: { term: planting.short_code }
    end

    it 'goes to the planting' do
      expect(response).to redirect_to(planting_path(planting))
    end
  end
end
