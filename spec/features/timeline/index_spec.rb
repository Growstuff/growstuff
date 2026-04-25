# frozen_string_literal: true

require 'rails_helper'

describe "timeline", :js do
  let(:member) { create(:member) }
  let(:planting_friend) { create(:member) }
  let(:post_friend) { create(:member) }

  before do
    member.followed << planting_friend
    member.followed << post_friend
  end

  describe 'visit timeline' do
    let!(:friend_planting) { create(:planting, owner: planting_friend, planted_at: 1.day.ago) }
    let!(:friend_harvest) { create(:planting, owner: post_friend, planted_at: 3.years.ago) }
    let!(:finished_planting) { create(:finished_planting, owner: planting_friend) }
    let!(:no_planted_at_planting) { create(:planting, owner: post_friend, planted_at: nil) }
    let!(:friend_photo) { create(:photo, owner: planting_friend) }
    let!(:friend_post) { create(:post, author: post_friend) }
    let!(:liked_post) { create(:like, likeable: friend_photo, member: post_friend) }
    let!(:liked_photo) { create(:like, likeable: friend_post, member: planting_friend) }

    before do
      login_as(member)
      visit timeline_index_path
    end

    describe 'show the activity' do
      it { expect(page).to have_link href: planting_path(friend_planting) }
      it { expect(page).to have_link href: planting_path(friend_harvest) }
      it { expect(page).to have_link href: planting_path(finished_planting) }
      it { expect(page).to have_no_link href: planting_path(no_planted_at_planting) }
      it { expect(page).to have_link href: photo_path(friend_photo) }
      it { expect(page).to have_link href: post_path(friend_post) }
    end

    describe 'shows the friends you follow' do
      it { expect(page).to have_link href: member_path(planting_friend) }
      it { expect(page).to have_link href: member_path(post_friend) }
    end
  end
end
