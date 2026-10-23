# frozen_string_literal: true

require 'rails_helper'

describe JobIdeasController do
  include ActiveSupport::Testing::TimeHelpers

  let(:member) { create(:member) }
  let(:today) { Date.new(2026, 10, 23) }
  let(:crop) { create(:crop, name: 'garlic', perennial: false) }

  before do
    travel_to(today.in_time_zone.change(hour: 12))
    sign_in member
    create(:job, :finished_without_time, owner: member, name: 'Snip off scapes', due_date: Date.new(2025, 10, 28), jobbable: crop)
  end

  describe 'GET /job_ideas' do
    before { get job_ideas_path }

    it 'responds with ok' do
      expect(response).to have_http_status(:ok)
    end

    it 'suggests the job' do
      expect(Capybara.string(response.body)).to have_css('.job-ideas', text: 'Snip off scapes')
    end

    it 'says why' do
      expect(response.body).to include('You did this on 28 Oct.')
    end

    it 'does not point to itself with the yellow box' do
      expect(Capybara.string(response.body)).to have_no_css('.notepad-ideas')
    end

    it 'shows the notepad beside the ideas' do
      expect(response.body).to include('notepad-groups')
    end

    it 'names the section' do
      expect(response.body).to include('At this time of year')
    end
  end

  describe 'GET /job_ideas with a source switched off' do
    before { get job_ideas_path(skip: ['mine']) }

    it 'leaves out what that source suggests' do
      expect(Capybara.string(response.body)).to have_no_css('.job-ideas', text: 'Snip off scapes')
    end
  end

  describe 'GET /job_ideas with a template for a crop they grow' do
    let(:page) { Capybara.string(response.body) }
    let(:tomato) { create(:crop, name: 'tomato') }
    let(:template) { create(:crop_job_template, crop: tomato, status: 'published') }

    before do
      create(:planting, owner: member, crop: tomato, planted_at: today - 1.day)
      create(:crop_job_step, crop_job_template: template, name: 'Stake', offset_amount: 2)
      create(:crop_job_step, crop_job_template: template, name: 'Feed', offset_amount: 4)
      get job_ideas_path
    end

    it 'offers to add all its jobs' do
      expect(page).to have_button('Add all 2')
    end

    it 'lists the jobs before they are added' do
      expect(page).to have_css('.idea-preview li', count: 2, visible: :all)
    end

    it 'gives each job\'s day' do
      expect(page).to have_css('.idea-preview li', text: '5 Nov Stake', visible: :all)
    end
  end

  describe 'GET /job_ideas when signed out' do
    before do
      sign_out member
      get job_ideas_path
    end

    it 'sends them to sign in' do
      expect(response).to redirect_to(new_member_session_path)
    end
  end

  describe 'POST /job_ideas' do
    let(:key) { "past_job:snip off scapes:#{crop.id}" }

    before { post job_ideas_path, params: { key: } }

    it 'adds the job' do
      expect(member.jobs.active.pluck(:name)).to eq ['Snip off scapes']
    end

    it 'adds it about the crop' do
      expect(member.jobs.active.first.jobbable).to eq crop
    end

    it 'goes back to the ideas' do
      expect(response).to redirect_to(job_ideas_path)
    end

    context 'with an idea that is not on offer' do
      let(:key) { 'past_job:something else:' }

      it 'adds nothing' do
        expect(member.jobs.active).to be_empty
      end
    end

    context 'with a planting idea' do
      let(:key) { "past_planting:#{crop.id}" }

      before do
        create(:planting, owner: member, crop:, planted_at: Date.new(2025, 10, 28))
        post job_ideas_path, params: { key: }
      end

      it 'adds a job to plant the crop' do
        expect(member.jobs.action_plant.pluck(:name)).to eq ['Plant garlic']
      end

      it 'no longer suggests it' do
        expect(JobIdeas.new(member, today:).ideas.map(&:key)).not_to include(key)
      end
    end
  end

  describe 'POST /job_ideas/hide' do
    let(:key) { "past_job:snip off scapes:#{crop.id}" }
    let(:hidden) { member.job_idea_dismissals.hiding.find_by(key:) }

    it 'snoozes for a week' do
      post hide_job_ideas_path, params: { key:, length: 'week' }
      expect(hidden.hidden_until).to be_within(1.minute).of(1.week.from_now)
    end

    it 'dismisses for a year without a length' do
      post hide_job_ideas_path, params: { key: }
      expect(hidden.hidden_until).to be_within(1.minute).of(1.year.from_now)
    end

    it 'dismisses for a year with a length it does not offer' do
      post hide_job_ideas_path, params: { key:, length: 'decade' }
      expect(hidden.hidden_until).to be_within(1.minute).of(1.year.from_now)
    end

    it 'stops suggesting it' do
      post hide_job_ideas_path, params: { key: }
      get job_ideas_path
      expect(Capybara.string(response.body)).to have_no_css('.job-ideas', text: 'Snip off scapes')
    end
  end
end
