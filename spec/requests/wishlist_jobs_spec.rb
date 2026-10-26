# frozen_string_literal: true

require 'rails_helper'

describe 'Wishlist jobs' do
  let(:member) { FactoryBot.create(:member) }
  let(:crop) { FactoryBot.create(:crop) }

  context 'when signed in' do
    subject(:job) { Job.find_by(owner: member) }

    before do
      sign_in member
      post wishlist_jobs_path, params: { crop_id: crop.id }
    end

    it { expect(job.name).to eq "Plant #{crop.name}" }
    it { expect(job.jobbable).to eq crop }
    it { expect(job.due_date).to be_nil }
    it { expect(response).to redirect_to member_jobs_path(member, anchor: 'notepad-someday') }
  end

  context 'when signed out' do
    before { post wishlist_jobs_path, params: { crop_id: crop.id } }

    it { expect(Job.count).to eq 0 }
  end
end
