# frozen_string_literal: true

require 'rails_helper'

# Who a written record belongs to is decided by the token, not by the request.
RSpec.describe 'API ownership of written records' do
  include_context 'with an API member'

  let(:other_member) { create(:member) }
  let(:owner_relationship) { { owner: { data: { type: 'members', id: other_member.id.to_s } } } }

  def post_resource(type, attributes: {}, relationships: {})
    post "/api/v1/#{type}", params: { data: { type:, attributes:, relationships: } }.to_json, headers: auth_headers
  end

  describe 'creating a record that names another owner' do
    {
      'gardens' => -> { { attributes: { name: 'Mine' } } },
      'jobs'    => -> { { attributes: { name: 'Water the beans' } } },
      'seeds'   => -> { { relationships: { crop: { data: { type: 'crops', id: create(:crop).id.to_s } } } } }
    }.each do |type, data|
      context "with #{type}" do
        before do
          given = instance_exec(&data)
          post_resource type, attributes:    given[:attributes] || {},
                              relationships: owner_relationship.merge(given[:relationships] || {})
        end

        it 'is owned by the token holder' do
          expect(type.classify.constantize.last.owner).to eq(member)
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
      post_resource 'harvests', relationships: { planting: { data: { type: 'plantings', id: planting.id.to_s } } }
    end

    it 'takes the crop from the planting' do
      expect(Harvest.last.crop).to eq(planting.crop)
    end

    it 'defaults the harvest date to today' do
      expect(Harvest.last.harvested_at).to eq(Time.zone.today)
    end
  end
end
