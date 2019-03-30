require 'rails_helper'

describe "crop detail page", js: true do
  subject { page }

  let!(:member) { FactoryBot.create :member }

  let!(:crop) { FactoryBot.create :crop }

  let!(:planting) { FactoryBot.create :planting, crop: crop, owner: member }
  let!(:harvest)  { FactoryBot.create :harvest, crop: crop, owner: member  }
  let!(:seed)     { FactoryBot.create :seed, crop: crop, owner: member     }

  let!(:photo1) { FactoryBot.create(:photo, owner: member) }
  let!(:photo2) { FactoryBot.create(:photo, owner: member) }
  let!(:photo3) { FactoryBot.create(:photo, owner: member) }
  let!(:photo4) { FactoryBot.create(:photo, owner: member) }
  let!(:photo5) { FactoryBot.create(:photo, owner: member) }
  let!(:photo6) { FactoryBot.create(:photo, owner: member) }

  before do
    planting.photos << photo1
    planting.photos << photo2
    harvest.photos << photo3
    harvest.photos << photo4
    seed.photos << photo5
    seed.photos << photo6
    visit crop_path(crop)
  end

  shared_examples "shows photos" do
    describe "show planting photos" do
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo1.thumbnail_url}')]") }
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo2.thumbnail_url}')]") }
    end

    describe "show harvest photos" do
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo3.thumbnail_url}')]") }
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo4.thumbnail_url}')]") }
    end

    describe "show seed photos" do
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo5.thumbnail_url}')]") }
      it { is_expected.to have_xpath("//img[contains(@src,'#{photo6.thumbnail_url}')]") }
    end

    describe "link to more photos" do
      it { is_expected.to have_link "more photos" }
    end
  end

  context "when signed in" do
    before { login_as(FactoryBot.create(:member)) }
    include_examples "shows photos"
  end

  context "when signed in as photos owner" do
    before { login_as(member) }
    include_examples "shows photos"
  end

  context "when not signed in " do
    include_examples "shows photos"
  end
end
