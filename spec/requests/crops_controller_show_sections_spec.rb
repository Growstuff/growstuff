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
end
