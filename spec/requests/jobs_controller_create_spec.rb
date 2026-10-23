# frozen_string_literal: true

require 'rails_helper'

describe JobsController, '#create' do
  let(:member) { create(:member) }
  # The notepad adds a job with an AJAX request.
  let(:headers) { { 'X-Requested-With' => 'XMLHttpRequest' } }

  before { sign_in member }

  context 'with a name' do
    before { post jobs_path, params: { job: { name: 'Sow the peas' } }, headers: }

    it 'creates the job' do
      expect(member.jobs.pluck(:name)).to eq ['Sow the peas']
    end

    it 'responds with created' do
      expect(response).to have_http_status(:created)
    end

    it 'sends back the groups with the new job in them' do
      expect(response.body).to include('Sow the peas')
    end
  end

  context 'when adding from a garden\'s to-do list' do
    let(:garden) { create(:garden, owner: member) }
    let(:page) { Capybara.string(response.body) }

    before do
      create(:job, owner: member, name: 'Elsewhere')
      post jobs_path, params: { job: { name: 'Net the berries', garden_id: garden.id }, garden_id: garden.id }, headers:
    end

    it 'adds the job to the garden' do
      expect(member.jobs.find_by(name: 'Net the berries').garden).to eq garden
    end

    it 'sends back the garden\'s jobs' do
      expect(page).to have_css('.notepad-name', text: 'Net the berries')
    end

    it 'leaves out the jobs elsewhere' do
      expect(page).to have_no_css('.notepad-name', text: 'Elsewhere')
    end

    it 'leaves out the garden chip, as they are all for it' do
      expect(page).to have_no_css('.notepad-chip.garden')
    end
  end

  context 'with the link left empty, as the notepad sends it' do
    before { post jobs_path, params: { job: { name: 'Sow the peas', jobbable_type: '', jobbable_id: '' } }, headers: }

    it 'creates the job' do
      expect(member.jobs.pluck(:name)).to eq ['Sow the peas']
    end

    it 'links it to nothing' do
      expect(member.jobs.first.jobbable).to be_nil
    end
  end

  context 'with a planting of the member\'s to link to' do
    let(:planting) { create(:planting, owner: member) }

    before do
      post jobs_path, params: { job: { name: 'Stake the tomatoes', jobbable_type: 'Planting', jobbable_id: planting.id } }, headers:
    end

    it 'links the job to the planting' do
      expect(member.jobs.first.planting).to eq planting
    end
  end

  context 'with something else to link to' do
    before do
      post jobs_path, params: { job: { name: 'Water', jobbable_type: 'Member', jobbable_id: member.id } }, headers:
    end

    it 'rejects it' do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'without a name' do
    before { post jobs_path, params: { job: { name: '' } }, headers: }

    it 'rejects it' do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'creates nothing' do
      expect(member.jobs.count).to eq 0
    end
  end
end
