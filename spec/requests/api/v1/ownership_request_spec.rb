# frozen_string_literal: true

require 'rails_helper'

# Who a written record belongs to is decided by the token, not by the request.
RSpec.describe 'API ownership of written records' do
  include_context 'with an API member'

  let(:other_member) { create(:member) }
  let(:owner_relationship) { { owner: link_to('members', other_member.id) } }

  def post_resource(type, attributes: {}, relationships: {})
    post "/api/v1/#{type}", params: { data: { type:, attributes:, relationships: } }.to_json, headers: auth_headers
  end

  describe 'creating a record that names another owner' do
    {
      'gardens' => -> { { attributes: { name: 'Mine' } } },
      'jobs'    => -> { { attributes: { name: 'Water the beans' } } },
      'seeds'   => -> { { relationships: { crop: link_to('crops', create(:crop).id) } } }
    }.each do |type, data|
      context "with #{type}" do
        before do
          given = instance_exec(&data)
          post_resource type, attributes:    given[:attributes] || {},
                              relationships: owner_relationship.merge(given[:relationships] || {})
        end

        it { expect(response).to have_http_status(:created) }

        # Not `.last`: a member comes with a garden, which would pass for a request that created nothing.
        it 'is owned by the token holder' do
          expect(type.classify.constantize.find(json['data']['id']).owner).to eq(member)
        end
      end
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

  describe 'creating a harvest from a planting' do
    let(:planting) { create(:planting, owner: member, garden: create(:garden, owner: member)) }

    before do
      create(:plant_part)
      post_resource 'harvests', relationships: { planting: link_to('plantings', planting.id) }
    end

    it 'takes the crop from the planting' do
      expect(Harvest.last.crop).to eq(planting.crop)
    end

    it 'defaults the harvest date to today' do
      expect(Harvest.last.harvested_at).to eq(Time.zone.today)
    end
  end

  describe 'taking over another member\'s job by linking it to a garden you collaborate on' do
    let(:job) { create(:job, owner: other_member) }
    let(:garden) { create(:garden, owner: other_member) }

    before do
      create(:garden_collaborator, garden: garden, member: member)
      patch "/api/v1/jobs/#{job.id}",
            params:  { data: { type: 'jobs', id: job.id.to_s, attributes: { name: 'Mine now' },
                               relationships: { garden: link_to('gardens', garden.id) } } }.to_json,
            headers: auth_headers
    end

    it { expect(response).to have_http_status(:forbidden) }

    it 'leaves the job alone' do
      expect(job.reload).to have_attributes(name: 'Admire', garden_id: nil)
    end
  end

  describe 'changing another member\'s garden through your own job' do
    let(:job) { create(:job, owner: member) }
    let(:garden) { create(:garden, owner: other_member, name: 'Theirs') }

    before do
      patch "/api/v1/jobs/#{job.id}",
            params:  { data:     { type: 'jobs', id: job.id.to_s,
                                   relationships: { garden: { data: { type: 'gardens', id: garden.id.to_s, method: 'update' } } } },
                       included: [{ type: 'gardens', id: garden.id.to_s, attributes: { name: 'Hijacked' } }] }.to_json,
            headers: auth_headers
    end

    it { expect(response).to have_http_status(:bad_request) }

    it 'leaves the garden alone' do
      expect(garden.reload.name).to eq('Theirs')
    end
  end

  describe 'linking to a record that does not exist' do
    before do
      create(:plant_part)
      post_resource 'harvests', relationships: { planting: link_to('plantings', 0) }
    end

    it { expect(response).to have_http_status(:not_found) }

    it 'creates nothing' do
      expect(Harvest.count).to eq(0)
    end
  end

  describe 'linking to a record that does not exist through an attribute' do
    before do
      create(:plant_part)
      post_resource 'harvests', attributes: { 'planting-id' => 0 }
    end

    it { expect(response).to have_http_status(:not_found) }
  end

  describe 'moving another member\'s planting into your garden through a list of links' do
    let(:garden) { create(:garden, owner: member) }
    let(:planting) { create(:planting, owner: other_member) }

    before do
      create(:garden_collaborator, garden: garden, member: other_member)
      patch "/api/v1/gardens/#{garden.id}",
            params:  { data: { type: 'gardens', id: garden.id.to_s,
                               relationships: { plantings: { data: [{ type: 'plantings', id: planting.id.to_s }] } } } }.to_json,
            headers: auth_headers
    end

    it { expect(response).to have_http_status(:bad_request) }

    it 'leaves the planting where it was' do
      expect { planting.reload }.not_to change(planting, :garden_id)
    end
  end
end
