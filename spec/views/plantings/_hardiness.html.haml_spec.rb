# frozen_string_literal: true

require 'rails_helper'

describe 'plantings/_hardiness' do
  let(:planting) { build(:planting, hardiness: 'unknown', crop: build(:crop, hardiness:)) }
  let(:hardiness) { 'hardy' }

  before { render partial: 'plantings/hardiness', locals: { planting: } }

  it 'shows the card' do
    expect(rendered).to have_css '.plantinghardiness--crop'
  end

  context 'when nobody knows' do
    let(:hardiness) { 'unknown' }

    it 'shows nothing' do
      expect(rendered).to have_no_css '.plantinghardiness'
    end
  end
end
