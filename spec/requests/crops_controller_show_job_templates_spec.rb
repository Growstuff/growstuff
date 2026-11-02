# frozen_string_literal: true

require 'rails_helper'

describe CropsController, '#show job templates' do
  subject(:page) { Capybara.string(response.body) }

  let(:crop) { create(:tomato) }
  let(:template) { create(:crop_job_template, crop:, name: 'Tomato jobs', status: 'published') }
  let!(:step) { create(:crop_job_step, crop_job_template: template, name: 'Stake or cage the plants', offset_amount: 2) }

  before { get crop_path(crop) }

  it { is_expected.to have_no_css('.crop-job-templates h3') }
  it { is_expected.to have_css('.crop-job-step', text: 'Stake or cage the plants') }
  it { is_expected.to have_css('.crop-job-step', text: '2 weeks after planting out') }

  context 'when signed out' do
    it { is_expected.to have_link('Sign up to track these tasks and get other suggestions.', href: new_member_registration_path) }
  end

  context 'when signed in' do
    before do
      sign_in create(:member)
      get crop_path(crop)
    end

    it { is_expected.to have_no_css('.crop-job-signup') }
    it { is_expected.to have_css('.crop-job-add') }
  end

  context 'when signed in and the jobs are already in their jobs' do
    before do
      member = create(:member)
      sign_in member
      AddCropJobs.new(member, crop).call
      get crop_path(crop)
    end

    it { is_expected.to have_no_css('.crop-job-add') }
    it { is_expected.to have_css('.crop-job-added', text: 'Your jobs already have the tomato growing jobs.') }
    it { is_expected.to have_link('See your jobs.', href: jobs_path) }
  end

  context 'when signed in with a planting of a variety' do
    let(:member) { create(:member) }
    let(:variety) { create(:crop, name: 'cherry tomato', parent: crop) }
    let!(:planting) { create(:planting, crop: variety, owner: member, planted_at: Time.zone.today) }

    before do
      sign_in member
      get crop_path(crop)
    end

    it { is_expected.to have_css('.dropdown-toggle', text: 'Add tomato growing jobs to my jobs') }
    it { is_expected.to have_css('.dropdown-menu button.dropdown-item', text: 'Add to cherry tomato in') }
    it { is_expected.to have_css('.dropdown-item[data-bs-target="#crop-jobs-modal"]', text: 'A new tomato planting I\'m going to do') }

    context 'when the planting already has the jobs' do
      before do
        AddCropJobs.new(member, crop, planting:).call
        get crop_path(crop)
      end

      it { is_expected.to have_no_button(class: 'dropdown-item') }
      it { is_expected.to have_css('button.crop-job-add[data-bs-target="#crop-jobs-modal"]') }
    end

    context 'when the jobs are in for the planting and for one to come' do
      before do
        AddCropJobs.new(member, crop, planting:).call
        AddCropJobs.new(member, crop).call
        get crop_path(crop)
      end

      it { is_expected.to have_css('.crop-job-added') }
      it { is_expected.to have_no_css('.crop-job-templates .dropdown-toggle') }
    end
  end

  context 'when signed in without a planting' do
    before do
      sign_in create(:member)
      get crop_path(crop)
    end

    it { is_expected.to have_css('button.crop-job-add[data-bs-target="#crop-jobs-modal"]', text: 'Add tomato growing jobs to my jobs') }
    it { is_expected.to have_no_css('.crop-job-templates .dropdown-menu') }
    it { is_expected.to have_css('#crop-jobs-modal form') }
    it { is_expected.to have_field('When do you want to plant tomato?', with: AddCropJobs.default_planting_on.iso8601) }
    it { is_expected.to have_css('#crop-jobs-modal ol.crop-job-modal-steps li', text: 'Stake or cage the plants') }
  end

  context 'when signed out, there is no button to add the jobs' do
    it { is_expected.to have_no_css('.crop-job-add') }
  end

  context 'with two templates' do
    before do
      create(:crop_job_step, crop_job_template: create(:crop_job_template, crop:, name: 'Early jobs', status: 'published'))
      get crop_path(crop)
    end

    it { is_expected.to have_css('.crop-job-templates h3', text: 'Early jobs') }
    it { is_expected.to have_css('.crop-job-templates h3', text: 'Tomato jobs') }
  end

  context 'with a template for part of the year' do
    let(:template) { create(:crop_job_template, crop:, name: 'Tomato jobs', status: 'published', season: 'spring_summer') }

    it { is_expected.to have_css('.crop-job-templates h3', text: 'Tomato jobs') }
    it { is_expected.to have_css('.crop-notepad-season', text: 'Spring and summer') }
  end

  context 'with a draft template' do
    let(:template) { create(:crop_job_template, crop:, name: 'Tomato jobs', status: 'draft') }

    it { is_expected.to have_no_css('.crop-job-templates') }
  end

  context 'with a template written for the crop a variety belongs to' do
    let(:variety) { create(:crop, name: 'cherry tomato', parent: crop) }

    before { get crop_path(variety) }

    it { is_expected.to have_no_css('.crop-job-templates h3') }
  end

  context 'with a template for another crop' do
    let(:template) { create(:crop_job_template, crop: create(:crop, name: 'carrot'), name: 'Carrot jobs', status: 'published') }

    it { is_expected.to have_no_css('.crop-job-templates') }
  end

  context 'with a step that links to a page' do
    let!(:step) do
      create(:crop_job_step, crop_job_template: template, name: 'Pinch out side shoots', external_uri: 'https://example.com/pinch')
    end

    it { is_expected.to have_link('Pinch out side shoots', href: 'https://example.com/pinch') }
  end
end
