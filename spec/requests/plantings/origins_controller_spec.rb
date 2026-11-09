# frozen_string_literal: true

require 'rails_helper'

describe Plantings::OriginsController do
  describe 'PATCH /plantings/:slug/origin' do
    subject(:update) { patch planting_origin_path(planting), params: params, as: :json }

    let(:member) { create(:member) }
    let(:garden) { create(:garden, owner: member) }
    let(:planting) { create(:planting, owner: member, garden: garden) }
    let(:params) { { planting: { planted_from: 'seedling', seedling_attributes: { source: 'nursery', supplier: 'Kings' } } } }

    before { sign_in member }

    context 'with a seedling' do
      before { update }

      it { expect(response).to have_http_status(:ok) }
      it { expect(planting.reload.planted_from).to eq 'seedling' }
      it { expect(planting.reload.seedling.supplier).to eq 'Kings' }
    end

    context 'when answered twice' do
      before do
        update
        patch planting_origin_path(planting), params: { planting: { seedling_attributes: { supplier: 'Bunnings' } } }, as: :json
      end

      it 'keeps one seedling row' do
        expect(PlantingSeedling.where(planting: planting).pluck(:supplier)).to eq ['Bunnings']
      end
    end

    context 'with an invalid source' do
      let(:params) { { planting: { seedling_attributes: { source: 'moon' } } } }

      it 'is unprocessable' do
        update
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with a packet of a variety of the planting\'s crop' do
      let(:tomato) { create(:crop, name: 'tomato') }
      let(:brandywine) { create(:crop, name: 'brandywine tomato', parent: tomato) }
      let(:planting) { create(:planting, owner: member, garden: garden, crop: tomato) }
      let(:seed) { create(:seed, owner: member, crop: brandywine) }
      let(:params) { { planting: { planted_from: 'seed', parent_seed_id: seed.id } } }

      before { update }

      it 'links the packet' do
        expect(planting.reload.parent_seed).to eq seed
      end

      it 'changes the planting to the variety' do
        expect(planting.reload.crop).to eq brandywine
      end

      it 'sends the page the crop it was' do
        expect(response.parsed_body['url']).to include("crop_was=#{tomato.id}")
      end
    end

    context 'with a packet of another crop' do
      let(:seed) { create(:seed, owner: member) }
      let(:params) { { planting: { planted_from: 'seed', parent_seed_id: seed.id } } }

      it 'leaves the crop alone' do
        expect { update }.not_to(change { planting.reload.crop })
      end
    end

    context 'with someone else\'s packet' do
      let(:params) { { planting: { planted_from: 'seed', parent_seed_id: create(:seed).id } } }

      it 'is not found' do
        update
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is someone else\'s planting' do
      let(:planting) { create(:planting) }

      it 'is forbidden' do
        update
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
