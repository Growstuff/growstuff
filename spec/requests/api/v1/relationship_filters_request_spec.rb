# frozen_string_literal: true

require 'rails_helper'

# Filtering by a relationship's name, as in filter[owner]=1, as well as by its `-id` attribute.
RSpec.describe 'API relationship filters' do
  include_context 'with an API member'

  let!(:garden) { create(:garden, owner: member) }
  let!(:planting) { create(:planting, owner: member, garden: garden) }
  let!(:harvest) { create(:harvest, owner: member, planting: planting, crop: planting.crop) }
  let!(:job) { create(:job, owner: member, garden: garden) }
  let!(:other_planting) { create(:planting) }

  describe 'plantings by owner' do
    before { get "/api/v1/plantings?filter[owner]=#{member.id}", headers: read_headers }

    it { expect(ids).to eq([planting.id.to_s]) }
  end

  describe 'plantings by garden' do
    before { get "/api/v1/plantings?filter[garden]=#{garden.id}", headers: read_headers }

    it { expect(ids).to eq([planting.id.to_s]) }
  end

  describe 'plantings by crop' do
    before { get "/api/v1/plantings?filter[crop]=#{planting.crop_id}", headers: read_headers }

    it { expect(ids).to eq([planting.id.to_s]) }
  end

  describe 'gardens by owner' do
    before { get "/api/v1/gardens?filter[owner]=#{member.id}", headers: read_headers }

    it { expect(ids).to match_array(member.gardens.map { |g| g.id.to_s }) }
  end

  describe 'harvests by planting' do
    before { get "/api/v1/harvests?filter[planting]=#{planting.id}", headers: read_headers }

    it { expect(ids).to eq([harvest.id.to_s]) }
  end

  describe 'jobs by garden' do
    before { get "/api/v1/jobs?filter[garden]=#{garden.id}", headers: read_headers }

    it { expect(ids).to eq([job.id.to_s]) }
  end

  describe 'including the owner of gardens' do
    before { get "/api/v1/gardens?include=owner&filter[owner]=#{member.id}", headers: read_headers }

    it 'includes each owner once' do
      expect(json['included'].pluck('id')).to eq([member.id.to_s])
    end
  end
end
