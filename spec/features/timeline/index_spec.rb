# frozen_string_literal: true

require 'rails_helper'

describe "timeline", :js do
  let(:member) { create(:member) }
  let(:friend1) { create(:member) }
  let(:friend2) { create(:member) }

  before do
    member.followed << friend1
    member.followed << friend2
  end

  describe 'visit timeline' do
    let!(:friend_planting) { create(:planting, owner: friend1, planted_at: 1.day.ago) }
    let!(:friend_harvest) { create(:planting, owner: friend2, planted_at: 3.years.ago) }
    let!(:finished_planting) { create(:finished_planting, owner: friend1) }
    let!(:no_planted_at_planting) { create(:planting, owner: friend2, planted_at: nil) }
    let!(:friend_photo) { create(:photo, owner: friend1) }
    let!(:friend_post) { create(:post, author: friend2) }
    let!(:liked_post) { create(:like, likeable: friend_photo, member: friend2) }
    let!(:liked_photo) { create(:like, likeable: friend_post, member: friend1) }

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
      it { expect(page).to have_link href: member_path(friend1) }
      it { expect(page).to have_link href: member_path(friend2) }
    end
  end
end
