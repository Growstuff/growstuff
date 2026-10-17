# frozen_string_literal: true

require 'rails_helper'

# A planting dated in the future is a plan: it doesn't exist yet, so it isn't
# listed or shown.
describe PlantingsController, 'planned plantings' do
  let(:owner) { create(:member) }
  let(:crop) { create(:crop, name: 'basil') }
  let!(:plan) { create(:planting, owner:, garden: owner.gardens.first, crop:, planted_at: 1.week.from_now.to_date) }
  let!(:sown) do
    create(:planting, owner:, garden: owner.gardens.first, crop: create(:crop, name: 'lettuce'), planted_at: 1.day.ago.to_date)
  end

  describe 'the planting page' do
    before { get planting_path(plan) }

    it { expect(response.body).to include "doesn't exist yet" }
    it { expect(response.body).to include owner.login_name }
    it('shows nothing else about it') { expect(response.body).not_to include 'basil' }
  end

  describe 'the planting page as JSON' do
    before { get planting_path(plan, format: :json) }

    it { expect(response).to have_http_status(:not_found) }
  end

  describe 'the plantings list' do
    before { get plantings_path(all: 1) }

    it { expect(response.body).to include 'lettuce' }
    it { expect(response.body).not_to include 'basil' }
  end

  describe "the owner's plantings list" do
    before { get member_plantings_path(owner) }

    it { expect(response.body).not_to include 'basil' }
  end
end
