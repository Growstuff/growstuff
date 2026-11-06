# frozen_string_literal: true

require 'rails_helper'

describe Seed, '#default_photo' do
  subject { seed.default_photo }

  let(:seed) { create(:seed) }
  let(:front) { create(:photo, owner: seed.owner) }
  let(:back) { create(:photo, owner: seed.owner, likes_count: 10) }
  let(:plain) { create(:photo, owner: seed.owner) }

  context 'with a front and a more liked plain photo' do
    let(:plain) { create(:photo, owner: seed.owner, likes_count: 10) }

    before do
      seed.photo_associations.create!(photo: front, label: 'front')
      seed.photo_associations.create!(photo: plain)
    end

    it { is_expected.to eq front }
  end

  context 'with a more liked back and a plain photo' do
    before do
      seed.photo_associations.create!(photo: back, label: 'back')
      seed.photo_associations.create!(photo: plain)
    end

    it { is_expected.to eq plain }
  end

  context 'with only a back' do
    before { seed.photo_associations.create!(photo: back, label: 'back') }

    it { is_expected.to be_nil }
  end
end
