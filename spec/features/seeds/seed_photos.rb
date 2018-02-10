require 'rails_helper'
require 'custom_matchers'

feature "Seeds", :js do
  subject do
    login_as member
    visit seed_path(seed)
    page
  end
  let(:member) { FactoryBot.create :member }
  let!(:seed) { FactoryBot.create :seed, owner: member }

  it { is_expected.to have_content 'Add photo' }

  # context 'no photos' do
  #   it { is_expected.to have_content 'no photos' }
  # end
  context 'has one photo' do
    before { seed.photos = [photo] }
    let!(:photo) { FactoryBot.create :photo, title: 'hello photo' }

    it { is_expected.to have_xpath("//img[contains(@src,'#{photo.thumbnail_url}')]") }
    it { is_expected.to have_xpath("//a[contains(@href,'#{photo_path(photo)}')]") }
  end
  context 'has 50 photos' do
    before { seed.photos = photos }
    let!(:photos) { FactoryBot.create_list :photo, 50 }

    it "shows newest photo" do
      is_expected.to have_xpath("//img[contains(@src,'#{photos.last.thumbnail_url}')]")
    end
    it "links to newest photo" do
      is_expected.to have_xpath("//a[contains(@href,'#{photo_path(photos.last)}')]")
    end
    it "does not show oldest photo" do
      is_expected.not_to have_xpath("//img[contains(@src,'#{photos.first.thumbnail_url}')]")
    end
    it "does not link to oldest photo" do
      is_expected.not_to have_xpath("//a[contains(@href,'#{photo_path(photos.first)}')]")
    end
  end
end
