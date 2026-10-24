# frozen_string_literal: true

require 'rails_helper'

# Filtering by a relationship name, rather than by its `-id` attribute. These return a 500 under
# jsonapi-resources 0.10.7 on Rails 8.1, so they are pending until the API moves off it.
RSpec.describe 'API relationship filters' do
  include_context 'with an API member'

  let!(:garden) { create(:garden, owner: member) }
  let!(:planting) { create(:planting, owner: member, garden: garden) }
  let!(:harvest) { create(:harvest, owner: member, planting: planting, crop: planting.crop) }
  let!(:job) { create(:job, owner: member, garden: garden) }

  def ids
    json['data'].pluck('id')
  end

  describe 'plantings by owner' do
    before do
      pending 'jsonapi-resources fails to join the owner on Rails 8.1'
      get "/api/v1/plantings?filter[owner]=#{member.id}", headers: read_headers
    end

    it { expect(ids).to eq([planting.id.to_s]) }
  end

  describe 'plantings by garden' do
    before do
      pending 'jsonapi-resources joins the wrong table on Rails 8.1'
      get "/api/v1/plantings?filter[garden]=#{garden.id}", headers: read_headers
    end

    it { expect(ids).to eq([planting.id.to_s]) }
  end

  describe 'gardens by owner' do
    before do
      pending 'jsonapi-resources fails to join the owner on Rails 8.1'
      get "/api/v1/gardens?filter[owner]=#{member.id}", headers: read_headers
    end

    it { expect(ids).to eq([garden.id.to_s]) }
  end

  describe 'harvests by planting' do
    before do
      pending 'jsonapi-resources joins the wrong table on Rails 8.1'
      get "/api/v1/harvests?filter[planting]=#{planting.id}", headers: read_headers
    end

    it { expect(ids).to eq([harvest.id.to_s]) }
  end

  describe 'jobs by garden' do
    before do
      pending 'jsonapi-resources joins the wrong table on Rails 8.1'
      get "/api/v1/jobs?filter[garden]=#{garden.id}", headers: read_headers
    end

    it { expect(ids).to eq([job.id.to_s]) }
  end

  describe 'including the owner of gardens' do
    before do
      pending 'jsonapi-resources fails to join the owner on Rails 8.1'
      get '/api/v1/gardens?include=owner', headers: read_headers
    end

    it { expect(json['included'].pluck('type')).to eq(['members']) }
  end

  describe 'a garden\'s owner' do
    before do
      pending 'jsonapi-resources fails to join the owner on Rails 8.1'
      get "/api/v1/gardens/#{garden.id}/owner", headers: read_headers
    end

    it { expect(json['data']['id']).to eq(member.id.to_s) }
  end
end
