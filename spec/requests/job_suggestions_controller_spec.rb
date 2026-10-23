# frozen_string_literal: true

require 'rails_helper'

describe JobSuggestionsController do
  let(:member) { create(:member) }
  let(:carrot) { create(:crop, name: 'carrot') }
  let(:suggestions) { response.parsed_body }

  before { sign_in member }

  context 'with a crop that has the member\'s planting and seeds' do
    let!(:planting) { create(:planting, owner: member, crop: carrot) }
    let!(:seed) { create(:seed, owner: member, crop: carrot) }

    before { get job_suggestions_path, params: { q: 'carr' } }

    it 'offers the planting, then the seeds, then the crop' do
      expect(suggestions.pluck('jobbable_type')).to eq %w(Planting Seed Crop)
    end

    it 'says which planting' do
      expect(suggestions.first['jobbable_id']).to eq planting.id
    end

    it 'gives each suggestion the crop\'s icon' do
      expect(suggestions.pluck('icon_url').uniq).to eq [crop_path(carrot, format: 'svg')]
    end

    it 'says which seeds' do
      expect(suggestions.second['jobbable_id']).to eq seed.id
    end
  end

  context 'with plantings and seeds that are someone else\'s' do
    before do
      create(:planting, crop: carrot)
      create(:seed, crop: carrot)
      get job_suggestions_path, params: { q: 'carr' }
    end

    it 'offers only the crop' do
      expect(suggestions.pluck('jobbable_type')).to eq ['Crop']
    end
  end

  context 'without a match' do
    before { get job_suggestions_path, params: { q: 'zzzz' } }

    it 'offers nothing' do
      expect(suggestions).to eq []
    end
  end

  context 'without signing in' do
    before do
      sign_out member
      get job_suggestions_path, params: { q: 'carr' }
    end

    it 'redirects to sign in' do
      expect(response).to redirect_to(new_member_session_path)
    end
  end

  context 'in a garden\'s to-do list' do
    let(:garden) { create(:garden, owner: member) }
    let(:other_garden) { create(:garden, owner: member) }
    let!(:here) { create(:planting, owner: member, crop: carrot, garden:) }
    let!(:there) { create(:planting, owner: member, crop: carrot, garden: other_garden) }

    before do
      create(:seed, owner: member, crop: carrot)
      get job_suggestions_path, params: { q: 'carr', garden_id: garden.id }
    end

    it 'offers only plantings' do
      expect(suggestions.pluck('jobbable_type')).to eq ['Planting']
    end

    it 'offers only the ones in that garden' do
      expect(suggestions.pluck('jobbable_id')).to eq [here.id]
    end

    it 'does not say which garden, as they are all in it' do
      expect(suggestions.first['label']).to eq 'carrot'
    end
  end

  context 'in a garden with no such plant' do
    let(:garden) { create(:garden, owner: member) }

    before do
      create(:planting, owner: member, crop: carrot)
      get job_suggestions_path, params: { q: 'carr', garden_id: garden.id }
    end

    it 'offers nothing' do
      expect(suggestions).to eq []
    end
  end
end
