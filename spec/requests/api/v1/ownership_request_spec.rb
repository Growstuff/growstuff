# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API ownership of written records' do
  include_context 'with an API member'

  let(:other_member) { create(:member) }
  let(:crop) { create(:crop) }
  let(:owner_relationship) { { owner: { data: { type: 'members', id: other_member.id.to_s } } } }

  def post_resource(path, type, attributes: {}, relationships: {})
    post path, params: { data: { type:, attributes:, relationships: } }.to_json, headers: auth_headers
  end

  describe 'creating a garden' do
    before { post_resource '/api/v1/gardens', 'gardens', attributes: { name: 'Mine' } }

    it { expect(Garden.last.owner).to eq(member) }
  end

  describe 'creating a garden that names another owner' do
    before do
      post_resource '/api/v1/gardens', 'gardens', attributes: { name: 'Mine' }, relationships: owner_relationship
    end

    it 'is owned by the token holder' do
      expect(Garden.last.owner).to eq(member)
    end
  end

  describe 'creating a planting' do
    let(:garden) { create(:garden, owner: member) }

    before do
      post_resource '/api/v1/plantings', 'plantings',
                    relationships: { crop:   { data: { type: 'crops', id: crop.id.to_s } },
                                     garden: { data: { type: 'gardens', id: garden.id.to_s } } }
    end

    it { expect(Planting.last.owner).to eq(member) }
  end

  describe 'creating a harvest from a planting' do
    let(:planting) { create(:planting, owner: member, garden: create(:garden, owner: member)) }

    before do
      create(:plant_part)
      post_resource '/api/v1/harvests', 'harvests',
                    relationships: { planting: { data: { type: 'plantings', id: planting.id.to_s } } }
    end

    it 'is owned by the token holder' do
      expect(Harvest.last.owner).to eq(member)
    end

    it 'takes the crop from the planting' do
      expect(Harvest.last.crop).to eq(planting.crop)
    end

    it 'defaults the harvest time to now' do
      expect(Harvest.last.harvested_at).to eq(Time.zone.today)
    end
  end

  describe 'creating a seed' do
    before do
      post_resource '/api/v1/seeds', 'seeds',
                    relationships: { crop: { data: { type: 'crops', id: crop.id.to_s } } }
    end

    it { expect(Seed.last.owner).to eq(member) }
  end

  describe 'creating a seed that names another owner' do
    before do
      post_resource '/api/v1/seeds', 'seeds',
                    relationships: owner_relationship.merge(crop: { data: { type: 'crops', id: crop.id.to_s } })
    end

    it 'is owned by the token holder' do
      expect(Seed.last.owner).to eq(member)
    end
  end

  describe 'creating a job that names another owner' do
    before do
      post_resource '/api/v1/jobs', 'jobs', attributes: { name: 'Water the beans' }, relationships: owner_relationship
    end

    it 'is owned by the token holder' do
      expect(Job.last.owner).to eq(member)
    end
  end

  describe 'creating a job' do
    before { post_resource '/api/v1/jobs', 'jobs', attributes: { name: 'Water the beans' } }

    it { expect(response).to have_http_status(:created) }

    it 'is owned by the token holder' do
      expect(Job.last.owner).to eq(member)
    end

    it 'keeps the name' do
      expect(Job.last.name).to eq('Water the beans')
    end
  end

  describe 'creating a job without a token' do
    before do
      post '/api/v1/jobs',
           params:  { data: { type: 'jobs', attributes: { name: 'Water the beans' } } }.to_json,
           headers: write_headers
    end

    it { expect(response).to have_http_status(:unauthorized) }
  end

  describe 'deleting your own job' do
    let!(:job) { create(:job, owner: member) }

    before { delete "/api/v1/jobs/#{job.id}", headers: auth_headers }

    it { expect(response).to have_http_status(:no_content) }

    it 'removes the job' do
      expect(Job.find_by(id: job.id)).to be_nil
    end
  end

  describe 'deleting another member\'s job' do
    let!(:job) { create(:job, owner: other_member) }

    before { delete "/api/v1/jobs/#{job.id}", headers: auth_headers }

    it { expect(response).to have_http_status(:forbidden) }

    it 'keeps the job' do
      expect(Job.find_by(id: job.id)).to be_present
    end
  end

  describe 'updating your own garden to name another owner' do
    let!(:garden) { create(:garden, owner: member) }

    before do
      patch "/api/v1/gardens/#{garden.id}",
            params:  { data: { type: 'gardens', id: garden.id.to_s, relationships: owner_relationship } }.to_json,
            headers: auth_headers
    end

    it 'keeps the original owner' do
      expect(garden.reload.owner).to eq(member)
    end
  end
end
