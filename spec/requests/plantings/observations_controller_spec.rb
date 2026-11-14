# frozen_string_literal: true

require 'rails_helper'

describe Plantings::ObservationsController do
  let(:member) { create(:member) }
  let(:garden) { create(:garden, owner: member) }
  let(:planting) { create(:planting, owner: member, garden: garden) }

  describe 'POST /plantings/:slug/observations' do
    subject(:create_observation) { post planting_observations_path(planting), params: params, as: :json }

    let(:params) { { observation: { kind: 'wilting', description: 'Droopy by noon' } } }

    context 'when signed in as the owner' do
      before { sign_in member }

      it 'records it, by them, as of now' do
        expect { create_observation }.to change(planting.observations, :count).by(1)
        observation = planting.observations.last
        expect(observation).to have_attributes(kind: 'wilting', description: 'Droopy by noon', author: member)
        expect(observation.observed_at).to be_within(1.minute).of(Time.zone.now)
      end

      it 'answers with the garden card' do
        create_observation
        expect(response).to have_http_status(:created)
        expect(response.parsed_body['garden']['id']).to eq garden.id
      end

      context 'with a day' do
        let(:params) { { observation: { kind: 'flowering', observed_at: '2026-01-05' } } }

        it { expect { create_observation }.to change { planting.observations.pick(:observed_at)&.to_date }.to(Date.new(2026, 1, 5)) }
      end

      context 'with no kind, which is other' do
        let(:params) { { observation: { kind: nil, description: 'Odd spots' } } }

        it 'saves it without one' do
          expect { create_observation }.to change(planting.observations, :count).by(1)
          expect(planting.observations.last.kind).to be_nil
        end
      end

      context 'with a kind that does not exist' do
        let(:params) { { observation: { kind: 'aliens' } } }

        it 'is unprocessable and saves nothing' do
          expect { create_observation }.not_to change(Observation, :count)
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'with a day in the future' do
        let(:params) { { observation: { kind: 'flowering', observed_at: 3.days.from_now.to_date.to_s } } }

        it 'is unprocessable' do
          create_observation
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context 'when signed in as a collaborator' do
      let(:collaborator) { create(:member) }

      before do
        create(:garden_collaborator, garden: garden, member: collaborator)
        sign_in collaborator
      end

      it 'records it, by them' do
        create_observation
        expect(planting.observations.last.author).to eq collaborator
      end
    end

    context 'when signed in as someone else' do
      before { sign_in create(:member) }

      it 'is refused' do
        expect { create_observation }.not_to change(Observation, :count)
        expect(response).to have_http_status(:forbidden).or have_http_status(:found)
      end
    end

    context 'when signed out' do
      it 'is refused' do
        expect { create_observation }.not_to change(Observation, :count)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /plantings/:slug/observations/:id' do
    subject(:delete_observation) { delete planting_observation_path(planting_slug: planting.slug, id: observation.id) }

    let!(:observation) { create(:observation, planting: planting) }

    context 'when signed in as the owner' do
      before { sign_in member }

      it 'removes it and goes back to the timeline' do
        expect { delete_observation }.to change(Observation, :count).by(-1)
        expect(response).to redirect_to(planting_path(planting, anchor: 'observations'))
      end
    end

    context 'when signed in as someone else' do
      before { sign_in create(:member) }

      it 'keeps it' do
        expect { delete_observation }.not_to change(Observation, :count)
      end
    end
  end
end
