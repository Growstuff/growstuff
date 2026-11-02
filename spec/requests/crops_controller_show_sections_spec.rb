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
end
