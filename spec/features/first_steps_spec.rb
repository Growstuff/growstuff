# frozen_string_literal: true

require 'rails_helper'

describe 'first steps list' do
  subject { page }

  let(:member) { create(:member) }
  let(:steps) { '.first-steps' }

  before { login_as member }

  context 'when they have not planted or planned anything' do
    before { visit crops_path }

    it { is_expected.to have_css steps }
    it { is_expected.to have_css '[data-react-component="FirstStepsPlanter"]', visible: :all }
    it { is_expected.to have_link href: suggestions_path }
  end

  context 'when on the home page, which has the steps in full' do
    before { visit root_path }

    it { is_expected.to have_no_css steps }
  end

  context 'when on the form for a new job' do
    before { visit new_job_path }

    it { is_expected.to have_no_css steps }
  end

  context 'with a planting' do
    before do
      create(:planting, owner: member)
      visit crops_path
    end

    it { is_expected.to have_no_css steps }
  end

  context 'with a job' do
    before do
      create(:job, owner: member)
      visit crops_path
    end

    it { is_expected.to have_no_css steps }
  end
end
