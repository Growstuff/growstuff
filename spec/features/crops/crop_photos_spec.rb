require 'rails_helper'

feature "crop detail page", js: true do
  subject { page }

  let(:member) { create :member }

  let(:crop) { create :crop, plantings: [planting], harvests: [harvest] }
  let(:planting) { create :planting, owner: member }
  let(:harvest) { create :harvest, owner: member }
  let(:valid_server) { 'https://farm5.staticflickr.com/' }
  let(:photo1) do
    create(:photo, owner:         member,
                   title:         'photo 1',
                   fullsize_url:  "#{valid_server}photo1.jpg",
                   thumbnail_url: "#{valid_server}thumb1.jpg")
  end
  let(:photo2) do
    create(:photo, owner:         member,
                   title:         'photo 2',
                   fullsize_url:  "#{valid_server}photo2.jpg",
                   thumbnail_url: "#{valid_server}thumb2.jpg")
  end
  let(:photo3) do
    create(:photo, owner:         member,
                   title:         'photo 3',
                   fullsize_url:  "#{valid_server}photo3.jpg",
                   thumbnail_url: "#{valid_server}thumb3.jpg")
  end
  let(:photo4) do
    create(:photo, owner:         member,
                   title:         'photo 4',
                   fullsize_url:  "#{valid_server}photo4.jpg",
                   thumbnail_url: "#{valid_server}thumb4.jpg")
  end

  before do
    planting.photos << photo1
    planting.photos << photo2
    harvest.photos << photo3
    harvest.photos << photo4
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

    describe "link to more photos" do
      it { is_expected.to have_link "more photos" }
    end
  end

  context "when signed in" do
    background { login_as(create(:member)) }
    include_examples "shows photos"
  end

  context "when signed in as photos owner" do
    background { login_as(member) }
    include_examples "shows photos"
  end

  context "when not signed in " do
    include_examples "shows photos"
  end
end
