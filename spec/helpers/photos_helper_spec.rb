# frozen_string_literal: true

require 'rails_helper'

describe PhotosHelper do
  let(:crop) { FactoryBot.create :crop }
  let(:crop_photo_of) { FactoryBot.create(:photo, source: 'openfarm') }
  let(:crop_photo_flickr) { FactoryBot.create(:photo, source: 'flickr') }

  let(:garden) { FactoryBot.create :garden }
  let(:planting)       { FactoryBot.create :planting, crop: crop, owner: garden.owner }
  let(:planting_photo) { FactoryBot.create(:photo, owner: garden.owner) }
  let(:harvest)        { FactoryBot.create :harvest, crop: crop, owner: garden.owner }
  let(:harvest_photo)  { FactoryBot.create(:photo, owner: garden.owner) }
  let(:seed)           { FactoryBot.create :seed, crop: crop, owner: garden.owner }
  let(:seed_photo)     { FactoryBot.create(:photo, owner: garden.owner) }

  describe "crops" do
    subject { crop_image_path(crop) }

    it { is_expected.to eq 'placeholder_600.png' }

    describe "with a planting" do
      before { planting.photos << planting_photo }

      it "uses planting photos" do
        expect(subject).to eq planting_photo.fullsize_url
      end
    end

    describe "with a harvest photos" do
      before { harvest.photos << harvest_photo }

      it "uses harvest photos" do
        expect(subject).to eq harvest_photo.fullsize_url
      end
    end

    describe "uses seed photo" do
      before { seed.photos << seed_photo }

      it "uses seed photos" do
        expect(subject).to eq seed_photo.fullsize_url
      end
    end
  end

  describe "gardens" do
    subject { garden_image_path(garden) }

    it { is_expected.to eq 'placeholder_600.png' }

    describe "has a flickr photo" do
      let(:garden_photo)   { FactoryBot.create(:photo, owner: garden.owner, source: 'flickr') }
      before { garden.photos << garden_photo }
      it { is_expected.to eq garden_photo.fullsize_url }
    end
  end

  describe 'plantings' do
    subject { planting_image_path(planting) }

    it { is_expected.to eq 'placeholder_600.png' }

    describe "uses planting's own photo" do
      before { planting.photos << planting_photo }

      it { is_expected.to eq planting_photo.fullsize_url }
    end
  end

  describe 'harvests' do
    subject { harvest_image_path(harvest) }

    it { is_expected.to eq 'placeholder_600.png' }

    describe "uses harvest's own photo" do
      before { harvest.photos << harvest_photo }

      it { is_expected.to eq harvest_photo.fullsize_url }
    end
  end

  describe 'seeds' do
    subject { seed_image_path(seed) }

    it { is_expected.to eq 'placeholder_600.png' }

    describe "uses seed's own photo" do
      before { seed.photos << seed_photo }

      it { is_expected.to eq seed_photo.fullsize_url }
    end
  end
end
