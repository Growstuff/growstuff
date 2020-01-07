# frozen_string_literal: true

require 'rails_helper'

describe 'Likeable', :js, search: true do
  let(:another_member) { FactoryBot.create(:london_member) }
  let!(:post)           { FactoryBot.create(:post, :reindex, author: member) }
  let!(:photo)          { FactoryBot.create(:photo, :reindex, owner: member) }

  before do
    Photo.reindex
  end

  include_context 'signed in member'

  describe 'photos' do
    def like_count_class
      "#photo-#{photo.id} .like-count"
    end

    shared_examples 'photo can be liked' do
      it 'can be liked' do
        visit path
        expect(page).to have_css(like_count_class, text: "0")
        click_link '0', class: 'like-btn'
        expect(page).to have_css(like_count_class, text: "1")

        # Reload page
        visit path
        expect(page).to have_css(like_count_class, text: "1")
        expect(page).to have_link '1'

        click_link '1', class: 'like-btn'
        expect(page).to have_css(like_count_class, text: "0")
      end

      it 'displays correct number of likes' do
        visit path
        expect(page).to have_css(like_count_class, text: "0")
        expect(page).to have_link '0'
        click_link '0', class: 'like-btn'
        expect(page).to have_css(like_count_class, text: "1")

        logout(member)
        login_as(another_member)
        visit path

        expect(page).to have_css(like_count_class, text: "1")
        click_link '1', class: 'like-btn'
        expect(page).to have_css(like_count_class, text: "2")
        logout(another_member)
      end
    end
    describe 'photos#index' do
      let(:path) { photos_path }
      include_examples 'photo can be liked'
    end
    describe 'photos#show' do
      let(:path) { photo_path(photo) }
      include_examples 'photo can be liked'
    end
    describe 'crops#show' do
      let(:crop) { FactoryBot.create :crop }
      let(:planting) { FactoryBot.create :planting, owner: member, crop: crop }
      let(:path) { crop_path(crop) }
      before { planting.photos << photo }
      include_examples 'photo can be liked'
    end
  end

  describe 'posts' do
    let(:like_count_class) { "#post-#{post.id} .like-count" }
    before { visit post_path(post) }
    it 'can be liked' do
      expect(page).to have_css(like_count_class, text: "0")
      expect(page).to have_link 'Like'
      click_link 'Like', class: 'like-btn'
      expect(page).to have_css(like_count_class, text: "1")

      # Reload page
      visit post_path(post)
      expect(page).to have_css(like_count_class, text: "1")
      expect(page).to have_link 'Unlike'

      click_link 'Unlike', class: 'like-btn'
      expect(page).to have_css(like_count_class, text: "0")
    end

    it 'displays correct number of likes' do
      expect(page).to have_link 'Like'
      click_link 'Like', class: 'like-btn'
      expect(page).to have_css(like_count_class, text: "1")

      logout(member)
      login_as(another_member)
      visit post_path(post)

      expect(page).to have_link 'Like'
      click_link 'Like', class: 'like-btn'
      expect(page).to have_css(like_count_class, text: "2")
      logout(another_member)
    end
  end
end
