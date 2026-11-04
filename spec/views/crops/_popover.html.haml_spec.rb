# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_popover' do
  subject { rendered }

  let(:crop) { create(:tomato) }

  before do
    create(:solanum_lycopersicum, crop:)
    create(:planting, crop:)
    crop.reload
    render partial: 'crops/popover', locals: { crop: }
  end

  it 'renders the scientific name' do
    expect(subject).to have_content 'Solanum lycopersicum'
  end

  it 'renders the localized count of plantings' do
    expect(subject).to have_content(I18n.t('crops.popover.planted_times', count: 1))
  end
end
