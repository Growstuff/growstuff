# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_hardiness' do
  let(:crop) { build_stubbed(:crop, hardiness:, hardiness_source:, lowest_tolerated_c:) }
  let(:hardiness) { 'half_hardy' }
  let(:hardiness_source) { 'seed_packets' }
  let(:lowest_tolerated_c) { nil }

  before { render partial: 'crops/hardiness', locals: { crop: } }

  it 'shows the level' do
    expect(rendered).to have_css '.hardiness-card strong', text: 'Half-hardy'
  end

  it 'says what the level means' do
    expect(rendered).to have_content 'A light frost is fine'
  end

  it 'says where it came from' do
    expect(rendered).to have_content "From members' seed packets"
  end

  it 'says it is a guess' do
    expect(rendered).to have_content 'Alpha – a guess, for entertainment only'
  end

  it 'leaves out the temperature when EcoCrop has none' do
    expect(rendered).to have_no_content 'EcoCrop says'
  end

  context 'with an EcoCrop temperature' do
    let(:hardiness) { 'hardy' }
    let(:hardiness_source) { 'ecocrop' }
    let(:lowest_tolerated_c) { -8.0 }

    it 'shows the temperature without a trailing zero' do
      expect(rendered).to have_content 'EcoCrop says frost at -8 °C kills it'
    end

    it 'names EcoCrop as the source' do
      expect(rendered).to have_content 'From the FAO EcoCrop database'
    end
  end

  context 'when the hardiness is unknown' do
    let(:hardiness) { 'unknown' }
    let(:hardiness_source) { nil }

    it 'shows no card' do
      expect(rendered).to be_blank
    end
  end
end
