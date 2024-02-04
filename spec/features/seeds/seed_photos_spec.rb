# frozen_string_literal: true

require 'rails_helper'
require 'custom_matchers'

describe "Seeds", :js do
  context 'signed in' do
    subject { page }

    include_context 'signed in member'
    before { visit seed_path(seed) }

    let(:member) { FactoryBot.create(:member)              }
    let!(:seed)  { FactoryBot.create(:seed, owner: member) }

    it {
      click_on "Actions"

      expect(subject).to have_content 'Add photo'
    }

    # context 'no photos' do
    #   it { is_expected.to have_content 'no photos' }
    # end
    context 'has one photo' do
      before do
        seed.photos = [photo]
        visit seed_path(seed)
      end

      let!(:photo) { FactoryBot.create(:photo, title: 'hello photo', owner: seed.owner) }

      it { is_expected.to have_xpath("//img[contains(@src,'#{photo.thumbnail_url}')]") }
      it { is_expected.to have_xpath("//a[contains(@href,'#{photo_path(photo)}')]") }
    end

    context 'has 50 photos' do
      before do
        seed.photos = photos

        visit seed_path(seed)
      end

      let!(:photos) { FactoryBot.create_list(:photo, 10 * 5, owner: seed.owner) }
      let(:newest_photo) { seed.photos.order(created_at: :desc, id: :desc).first }
      let(:oldest_photo) { seed.photos.order(created_at: :desc, id: :desc).last }

      it "shows newest photo" do
        expect(subject).to have_xpath("//img[contains(@src,'#{newest_photo.thumbnail_url}')]")
      end

      it "links to newest photo" do
        expect(subject).to have_xpath("//a[contains(@href,'#{photo_path(newest_photo)}')]")
      end

      it "does not show oldest photo" do
        expect(subject).to have_no_xpath("//img[contains(@src,'#{oldest_photo.thumbnail_url}')]")
      end

      it "does not link to oldest photo" do
        expect(subject).to have_no_xpath("//a[contains(@href,'#{photo_path(oldest_photo)}')]")
      end
    end
  end
end
