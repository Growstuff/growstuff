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
      before { seed.photos = [photo] }

      let!(:photo) { FactoryBot.create(:photo, title: 'hello photo', owner: seed.owner) }

      it { is_expected.to have_xpath("//img[contains(@src,'#{photo.thumbnail_url}')]") }
      it { is_expected.to have_xpath("//a[contains(@href,'#{photo_path(photo)}')]") }
    end

    context 'has 50 photos' do
      before { 
        seed.photos = photos

        visit seed_path(seed) 
      }

      let!(:photos) { FactoryBot.create_list(:photo, 10 * 5, owner: seed.owner) }

      it "shows newest photo" do
        expect(subject).to have_xpath("//img[contains(@src,'#{photos.last.thumbnail_url}')]")
      end

      it "links to newest photo" do
        expect(subject).to have_xpath("//a[contains(@href,'#{photo_path(photos.last)}')]")
      end

      it "does not show oldest photo" do
        expect(subject).to have_no_xpath("//img[contains(@src,'#{photos.first.thumbnail_url}')]")
      end

      it "does not link to oldest photo" do
        expect(subject).to have_no_xpath("//a[contains(@href,'#{photo_path(photos.first)}')]")
      end
    end
  end
end
