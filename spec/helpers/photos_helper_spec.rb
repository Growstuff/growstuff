require 'rails_helper'

describe PhotosHelper do
  let(:crop) { FactoryBot.create :crop }

  let(:garden) { FactoryBot.create :garden }
  let(:garden_photo) { FactoryBot.create(:photo, thumbnail_url: 'garden.jpg') }
  let(:planting) { FactoryBot.create :planting, crop: crop }
  let(:planting_photo) { FactoryBot.create(:photo, thumbnail_url: 'planting.jpg') }
  let(:harvest) { FactoryBot.create :harvest, crop: crop }
  let(:harvest_photo) { FactoryBot.create(:photo, thumbnail_url: 'harvest.jpg') }
  let(:seed) { FactoryBot.create :seed, crop: crop }
  let(:seed_photo) { FactoryBot.create(:photo, thumbnail_url: 'seed.jpg') }

  describe "crops" do
    subject { crop_image_path(crop) }

    it { is_expected.to eq 'placeholder_150.png' }

    describe "with a planting" do
      before { planting.photos << planting_photo }
      it "uses planting photos" do
        is_expected.to eq planting_photo.thumbnail_url
      end
    end

    describe "with a harvest photos" do
      before { harvest.photos << harvest_photo }
      it "uses harvest photos" do
        is_expected.to eq harvest_photo.thumbnail_url
      end
    end

    describe "uses seed photo" do
      before { seed.photos << seed_photo }
      it "uses seed photos" do
        is_expected.to eq seed_photo.thumbnail_url
      end
    end
  end

  describe "gardens" do
    subject { garden_image_path(garden) }
    it { is_expected.to eq 'placeholder_150.png' }

    describe "uses garden's own photo" do
      before { garden.photos << garden_photo }
      it { is_expected.to eq garden_photo.thumbnail_url }
    end
  end

  describe 'plantings' do
    subject { planting_image_path(planting) }
    it { is_expected.to eq 'placeholder_150.png' }
    describe "uses planting's own photo" do
      before { planting.photos << planting_photo }
      it { is_expected.to eq planting_photo.thumbnail_url }
    end
  end

  describe 'harvests' do
    subject { harvest_image_path(harvest) }
    it { is_expected.to eq 'placeholder_150.png' }
    describe "uses harvest's own photo" do
      before { harvest.photos << harvest_photo }
      it { is_expected.to eq harvest_photo.thumbnail_url }
    end
  end

  describe 'seeds' do
    subject { seed_image_path(seed) }
    it { is_expected.to eq 'placeholder_150.png' }

    describe "uses seed's own photo" do
      before { seed.photos << seed_photo }
      it { is_expected.to eq seed_photo.thumbnail_url }
    end
  end
end
