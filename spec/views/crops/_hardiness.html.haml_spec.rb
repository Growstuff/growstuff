# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_hardiness' do
  let(:crop) { build_stubbed(:crop, hardiness:, hardiness_source:) }
  let(:hardiness) { 'half_hardy' }
  let(:hardiness_source) { 'seed_packets' }

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

  context 'with a value set by a crop wrangler' do
    let(:hardiness) { 'hardy' }
    let(:hardiness_source) { 'manual' }

    it 'names the wrangler as the source' do
      expect(rendered).to have_content 'Set by a crop wrangler'
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
