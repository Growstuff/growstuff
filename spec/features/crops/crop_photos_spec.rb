require 'rails_helper'

feature "crop detail page", js: true do
  let(:crop) { create :crop, plantings: [planting], harvests: [harvest] }
  let(:planting) { create :planting, owner: member, photos: [photo1, photo2] }
  let(:harvest) { create :harvest, owner: member, photos: [photo3, photo4] }
  let(:photo1) do
    create(:photo, owner: member, title: 'photo 1',
                   fullsize_url: 'photo1.jpg', thumbnail_url: 'thumb1.jpg')
  end
  let(:photo2) do
    create(:photo, owner: member, title: 'photo 2',
                   fullsize_url: 'photo2.jpg', thumbnail_url: 'thumb2.jpg')
  end
  let(:photo3) do
    create(:photo, owner: member, title: 'photo 3',
                   fullsize_url: 'photo3.jpg', thumbnail_url: 'thumb3.jpg')
  end
  let(:photo4) do
    create(:photo, owner: member, title: 'photo 4',
                   fullsize_url: 'photo4.jpg', thumbnail_url: 'thumb4.jpg')
  end

  before { visit crop_path(crop) }

  context "when signed in member" do
    let(:member) { create :member }
    background { login_as(member) }
    subject { page }

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
end
