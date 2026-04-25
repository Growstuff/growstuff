# frozen_string_literal: true

require 'rails_helper'

describe "crop detail page", :js, :search do
  subject { page }

  let!(:owner_member) { create(:member) }

  let!(:crop) { create(:crop, :reindex) }

  let(:plant_part) { create(:plant_part, name: 'fruit') }

  let!(:harvest)  { create(:harvest, crop:, owner: owner_member, plant_part:) }
  let!(:planting) { create(:planting, crop:, owner: owner_member) }
  let!(:seed)     { create(:seed, crop:, owner: owner_member)     }

  let!(:first_planting_photo)  { create(:photo, owner: owner_member) }
  let!(:second_planting_photo) { create(:photo, owner: owner_member) }
  let!(:first_harvest_photo)   { create(:photo, owner: owner_member) }
  let!(:second_harvest_photo)  { create(:photo, owner: owner_member) }
  let!(:first_seed_photo)      { create(:photo, owner: owner_member) }
  let!(:second_seed_photo)     { create(:photo, owner: owner_member) }

  before do
    planting.photos << first_planting_photo
    planting.photos << second_planting_photo
    harvest.photos << first_harvest_photo
    harvest.photos << second_harvest_photo
    seed.photos << first_seed_photo
    seed.photos << second_seed_photo
    Crop.reindex
    visit crop_path(crop)
    expect(crop.photos.count).to eq 6
    expect(crop.photos.by_model(Planting).count).to eq 2
    expect(page).to have_content 'Photos'
  end

  shared_examples "shows photos" do
    describe "show planting photos" do
      it { is_expected.to have_xpath("//img[contains(@src,'#{first_planting_photo.fullsize_url}')]") }
      it { is_expected.to have_xpath("//img[contains(@src,'#{second_planting_photo.fullsize_url}')]") }
    end

    describe "show harvest photos" do
      it { is_expected.to have_xpath("//img[contains(@src,'#{first_harvest_photo.fullsize_url}')]") }
      it { is_expected.to have_xpath("//img[contains(@src,'#{second_harvest_photo.fullsize_url}')]") }
    end

    describe "show seed photos" do
      it { is_expected.to have_xpath("//img[contains(@src,'#{first_seed_photo.fullsize_url}')]") }
      it { is_expected.to have_xpath("//img[contains(@src,'#{second_seed_photo.fullsize_url}')]") }
    end

    describe "link to more photos" do
      it { is_expected.to have_link "more photos" }
    end
  end

  context "when signed in" do
    include_context 'signed in member'
    include_examples "shows photos"
  end

  context "when signed in as photos owner" do
    include_context 'signed in member'
    let(:member) { owner_member }

    include_examples "shows photos"
  end

  context "when not signed in" do
    include_examples "shows photos"
  end
end
