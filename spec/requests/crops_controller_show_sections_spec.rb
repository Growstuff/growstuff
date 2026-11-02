# frozen_string_literal: true

require 'rails_helper'

describe CropsController, '#show sections' do
  subject(:page) { Capybara.string(response.body) }

  let(:crop) { create(:tomato) }

  context 'when nobody has planted the crop' do
    before { get crop_path(crop) }

    it { is_expected.to have_no_css('section.crop-map') }
    it { is_expected.to have_no_css('section.photos') }
  end

  context 'when somebody has planted the crop' do
    before do
      create(:planting, crop:)
      get crop_path(crop)
    end

    it { is_expected.to have_css('section.crop-map #cropmap') }
  end

  context 'when the crop has a photo' do
    let(:planting) { create(:planting, crop:) }

    before do
      planting.photos << create(:photo, owner: planting.owner)
      get crop_path(crop)
    end

    it { is_expected.to have_css('section.photos') }
  end

  describe 'the link to add more attributes' do
    context 'when signed out' do
      before { get crop_path(crop) }

      it { is_expected.to have_no_link('Add more attributes') }
    end

    context 'when signed in as an ordinary member' do
      before do
        sign_in create(:member)
        get crop_path(crop)
      end

      it { is_expected.to have_no_link('Add more attributes') }
    end

    context 'when signed in as a crop wrangler' do
      before do
        sign_in create(:crop_wrangling_member)
        get crop_path(crop)
      end

      it { is_expected.to have_css('.section-header a.section-add', text: 'Add more attributes') }
    end

    context 'when a crop wrangler views a crop with every attribute' do
      let(:crop) { create(:tomato, height: 100, spread: 50, row_spacing: 30, growing_degree_days: 1000) }

      before do
        sign_in create(:crop_wrangling_member)
        get crop_path(crop)
      end

      it { is_expected.to have_no_link('Add more attributes') }
    end
  end

  describe 'the facts' do
    before { get crop_path(crop) }

    it { is_expected.to have_css('.prediction h2', text: 'Tomato facts') }
    it { is_expected.to have_no_css('.prediction h2', text: 'Growing tomatoes') }
  end

  describe 'the lifespan card' do
    before do
      crop.update!(perennial:, median_lifespan:)
      get crop_path(crop)
    end

    let(:median_lifespan) { 91 }

    context 'with an annual with a median lifespan of 13 weeks' do
      let(:perennial) { false }

      it { is_expected.to have_css('.lifespan-card .lifespan-word', text: 'Annual') }
      it { is_expected.to have_css('.lifespan-card .crop-median-lifespan', text: '13 weeks median lifespan') }
      it { is_expected.to have_css('.lifespan-card .fa-calendar') }
      it { is_expected.to have_no_css('.lifespan-card svg') }
    end

    context 'with an annual with a week or less' do
      let(:perennial) { false }
      let(:median_lifespan) { 0 }

      it { is_expected.to have_css('.lifespan-card', text: "We don't have enough data yet") }
      it { is_expected.to have_no_css('.lifespan-card', text: '0 weeks') }
    end

    context 'with an annual with no median lifespan' do
      let(:perennial) { false }
      let(:median_lifespan) { nil }

      it { is_expected.to have_no_css('.crop-median-lifespan') }
    end

    context 'with a perennial' do
      let(:perennial) { true }

      it { is_expected.to have_css('.lifespan-card .lifespan-word', text: 'Perennial') }
      it { is_expected.to have_no_css('.crop-median-lifespan') }
    end
  end

  describe 'the jobs section' do
    before do
      create(:crop_job_step, crop_job_template: create(:crop_job_template, crop:, status: 'published'))
      get crop_path(crop)
    end

    it { is_expected.to have_css('section.crop-jobs h2', text: 'Growing tomatoes') }
    it { is_expected.to have_css('section.crop-jobs .crop-job-templates') }
    it { is_expected.to have_no_css('section.prediction .crop-job-templates') }
  end

  describe 'a crop with no job templates' do
    before { get crop_path(crop) }

    it { is_expected.to have_no_css('section.crop-jobs') }
  end

  describe 'changing whether the crop is annual or perennial' do
    context 'when signed in as a crop wrangler' do
      before do
        sign_in create(:crop_wrangling_member)
        get crop_path(crop)
      end

      it { is_expected.to have_css('.lifespan-card .edit-link a.editable') }
      it { is_expected.to have_css('.lifespan-card select[name="crop[perennial]"]', visible: :all) }
      it { is_expected.to have_no_css('.lifespan-card input[type="submit"][value="toggle"]', visible: :all) }
    end

    context 'when signed in as an ordinary member' do
      before do
        sign_in create(:member)
        get crop_path(crop)
      end

      it { is_expected.to have_no_css('.lifespan-card .edit-link') }
      it { is_expected.to have_no_css('.lifespan-card select', visible: :all) }
    end
  end

  describe 'the row spacing card' do
    context 'with seed packets that give a row spacing' do
      before do
        create(:seed, crop:, row_spacing: 30)
        create(:seed, crop:, row_spacing: 60)
        create(:seed, crop:, row_spacing: nil)
        get crop_path(crop)
      end

      it { is_expected.to have_css('.fact-card', text: 'Row Spacing 45cm median of 2 seed packets') }
    end

    context 'with a crop row spacing and no packets that give one' do
      let(:crop) { create(:tomato, row_spacing: 25) }

      before { get crop_path(crop) }

      it { is_expected.to have_css('.fact-card', text: 'Row Spacing 25cm') }
      it { is_expected.to have_no_css('.fact-card', text: 'median of') }
    end

    context 'with neither' do
      before { get crop_path(crop) }

      it { is_expected.to have_no_css('.fact-card', text: 'Row Spacing') }
    end
  end
end
