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

      it { is_expected.to have_css('.fact-card', text: "Row Spacing 45cm median of members' seed packets") }
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

  describe 'the months to sow card' do
    let(:wellington) { create_located_member('Wellington, Wellington Region, New Zealand', -41.29, 174.78) }
    let(:london) { create_located_member('London, England', 51.5, -0.12) }

    context 'with packets from both hemispheres' do
      before do
        create(:seed, crop:, owner: wellington, sow_months: [9, 10, 11])
        create(:seed, crop:, owner: london, sow_months: [3, 4, 5])
        get crop_path(crop)
      end

      it { is_expected.to have_css('.sow-months-card .crop-sow-hemisphere', text: 'Southern hemisphere Sep–Nov') }
      it { is_expected.to have_css('.sow-months-card .crop-sow-hemisphere', text: 'Northern hemisphere Mar–May') }
    end

    context 'with a packet that says nothing about months' do
      before do
        create(:seed, crop:, owner: wellington, sow_months: [])
        get crop_path(crop)
      end

      it { is_expected.to have_no_css('.sow-months-card') }
    end
  end

  describe 'the growing facts a wrangler set, and the medians beside them' do
    context 'with a figure set and a median' do
      before do
        crop.update!(germination_days_min: 5, germination_days_max: 10)
        crop.update_columns(median_germination_days_min: 7, median_germination_days_max: 12) # rubocop:disable Rails/SkipsModelValidations
        get crop_path(crop)
      end

      it { is_expected.to have_css('.growing-fact strong', text: '5–10 days') }
      it { is_expected.to have_css('.growing-fact .crop-fact-median', text: "Members' seed packets: 7–12 days") }
    end

    context 'with a median only' do
      before do
        crop.update_columns(median_days_until_maturity_min: 59.6, median_days_until_maturity_max: 80) # rubocop:disable Rails/SkipsModelValidations
        get crop_path(crop)
      end

      it { is_expected.to have_css('.growing-fact strong', text: '60–80 days') }
      it { is_expected.to have_css('.growing-fact .crop-fact-median', text: "median of members' seed packets") }
    end

    context 'with a figure only' do
      before do
        crop.update!(days_until_maturity_min: 60, days_until_maturity_max: 80)
        get crop_path(crop)
      end

      it { is_expected.to have_css('.growing-fact strong', text: '60–80 days') }
      it { is_expected.to have_no_css('.growing-fact .crop-fact-median') }
    end

    context 'with months set and a median' do
      before do
        crop.update!(sow_months: [9, 10, 11])
        crop.update_columns(median_sow_months: [10, 11]) # rubocop:disable Rails/SkipsModelValidations
        get crop_path(crop)
      end

      it { is_expected.to have_css('.sow-months-card .crop-sow-hemisphere', text: 'Southern hemisphere Sep–Nov') }
      it { is_expected.to have_css('.sow-months-card .crop-sow-hemisphere', text: 'Northern hemisphere Mar–May') }
      it { is_expected.to have_css('.sow-months-card .crop-fact-median', text: "Members' seed packets: Oct–Nov south, Apr–May north") }
    end

    context 'with a row spacing set and a median' do
      before do
        crop.update!(row_spacing: 25)
        create(:seed, crop:, row_spacing: 30)
        get crop_path(crop)
      end

      it { is_expected.to have_css('.growing-fact strong', text: '25cm') }
      it { is_expected.to have_css('.growing-fact .crop-fact-median', text: "Members' seed packets: 30cm") }
    end
  end
end
