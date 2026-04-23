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

  let!(:photo1) { create(:photo, owner: owner_member) }
  let!(:photo2) { create(:photo, owner: owner_member) }
  let!(:photo3) { create(:photo, owner: owner_member) }
  let!(:photo4) { create(:photo, owner: owner_member) }
  let!(:photo5) { create(:photo, owner: owner_member) }
  let!(:photo6) { create(:photo, owner: owner_member) }

  before do
    planting.photos << photo1
    planting.photos << photo2
    harvest.photos << photo3
    harvest.photos << photo4
    seed.photos << photo5
    seed.photos << photo6
    Crop.reindex
    visit crop_path(crop)
    expect(crop.photos.count).to eq 6
    expect(crop.photos.by_model(Planting).count).to eq 2
    expect(page).to have_content 'Photos'
  end

  shared_examples "shows photos" do
    describe "show planting photos" do
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo1.fullsize_url}')]") }
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo2.fullsize_url}')]") }
    end

    describe "show harvest photos" do
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo3.fullsize_url}')]") }
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo4.fullsize_url}')]") }
    end

    describe "show seed photos" do
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo5.fullsize_url}')]") }
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo6.fullsize_url}')]") }
    end

    describe "link to more photos" do
      it { is_expected.to have_link "more photos" }
    end
  end

  context "when signed in" do
    include_context 'signed in member'
    it_behaves_like "shows photos"
  end

  context "when signed in as photos owner" do
    include_context 'signed in member'
    let(:member) { owner_member }

    it_behaves_like "shows photos"
  end

  context "when not signed in" do
    it_behaves_like "shows photos"
  end
end
