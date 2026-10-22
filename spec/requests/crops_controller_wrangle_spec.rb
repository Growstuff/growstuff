# frozen_string_literal: true

require 'rails_helper'

describe CropsController, '#wrangle' do
  let!(:tomato) { create(:crop, name: 'tomato') }
  let!(:cherry) { create(:crop, name: 'cherry tomato', parent: tomato) }
  let!(:apple) { create(:crop, name: 'Apple') }

  before { sign_in create(:crop_wrangling_member) }

  context 'by default' do
    before { get wrangle_crops_path }

    it 'lists crops with no parent' do
      expect(response.body).to include('tomato', 'Apple')
    end

    it 'leaves out crops with a parent' do
      expect(response.body).not_to include('cherry tomato')
    end

    it 'sorts by name, ignoring case' do
      expect(response.body.index('Apple')).to be < response.body.index('tomato')
    end
  end

  context 'when showing all crops' do
    before { get wrangle_crops_path(level: 'all') }

    it 'includes crops with a parent' do
      expect(response.body).to include('cherry tomato')
    end
  end

  context 'with pending crops' do
    let!(:pending) { create(:crop_request, name: 'mystery seedling') }

    before { get wrangle_crops_path(approval_status: 'pending') }

    it 'lists them' do
      expect(response.body).to include('mystery seedling')
    end

    it 'leaves out approved crops' do
      expect(response.body).not_to include('Apple')
    end
  end
end
