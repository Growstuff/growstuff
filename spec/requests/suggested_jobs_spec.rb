# frozen_string_literal: true

require 'rails_helper'

describe SuggestedJobsController, type: :request do
  let(:member) { create(:member) }
  let(:crop) { create(:crop, name: 'kale') }

  context 'when signed in' do
    before { sign_in member }

    it 'makes a job to plant the crop' do
      expect { post suggested_jobs_path, params: { crop_id: crop.id } }.to change(member.jobs, :count).by(1)
    end

    it 'links the job to the crop' do
      post suggested_jobs_path, params: { crop_id: crop.id }
      expect(member.jobs.last).to have_attributes(jobbable: crop, action: 'plant', due_date: nil)
    end

    context 'with the weather of the member\'s place held' do
      include ActiveSupport::Testing::TimeHelpers

      before do
        member.update_columns(latitude: -41.3, longitude: 174.7) # rubocop:disable Rails/SkipsModelValidations
        create(:climate_month, latitude: -41.25, longitude: 174.75, year: 2025, month: 7)
      end

      around { |example| travel_to(Date.new(2026, 11, 10)) { example.run } }

      it 'names the job for the season' do
        post suggested_jobs_path, params: { crop_id: crop.id, season: 'spring' }
        expect(member.jobs.last.name).to eq 'Plant kale for spring 2026'
      end

      it 'gives it a due date when the season starts' do
        post suggested_jobs_path, params: { crop_id: crop.id, season: 'autumn' }
        expect(member.jobs.last.due_date).to eq Date.new(2027, 3, 1)
      end
    end

    context 'when asked for JSON' do
      let(:headers) { { 'Accept' => 'application/json' } }

      it 'answers that the job was made, with its name' do
        post suggested_jobs_path, params: { crop_id: crop.id }, headers:, as: :json
        expect(response.parsed_body).to eq('added' => true, 'name' => 'Plant kale')
      end

      it 'answers created' do
        post suggested_jobs_path, params: { crop_id: crop.id }, headers:, as: :json
        expect(response).to have_http_status(:created)
      end

      it 'answers that nothing was made when it is there already' do
        create(:job, owner: member, jobbable: crop, action: 'plant', name: 'Plant kale')
        post suggested_jobs_path, params: { crop_id: crop.id }, headers:, as: :json
        expect(response.parsed_body).to eq('added' => false, 'name' => nil)
      end

      it 'does not redirect' do
        post suggested_jobs_path, params: { crop_id: crop.id }, headers:, as: :json
        expect(response).not_to be_redirect
      end
    end

    it 'goes back to the season it was added from' do
      post suggested_jobs_path, params: { crop_id: crop.id, season: 'winter' }
      expect(response).to redirect_to suggestions_path(season: 'winter')
    end

    it 'does not make a second job while the first is not done' do
      create(:job, owner: member, jobbable: crop, action: 'plant', name: 'Plant kale')
      expect { post suggested_jobs_path, params: { crop_id: crop.id } }.not_to change(member.jobs, :count)
    end

    it 'makes another once the first is done' do
      create(:job, owner: member, jobbable: crop, action: 'plant', finished: true)
      expect { post suggested_jobs_path, params: { crop_id: crop.id } }.to change(member.jobs, :count).by(1)
    end

    it 'does not make a job for a crop that is not approved' do
      pending_crop = create(:crop, approval_status: 'pending')
      post suggested_jobs_path, params: { crop_id: pending_crop.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when signed out' do
    it 'asks them to sign in' do
      post suggested_jobs_path, params: { crop_id: crop.id }
      expect(response).to redirect_to new_member_session_path
    end
  end
end
