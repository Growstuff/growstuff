# frozen_string_literal: true

require 'rails_helper'

describe "members/_stats" do
  let(:member) { create(:member) }

  context "with no stats items" do
    before { render partial: 'members/stats', locals: { member: } }

    it 'renders the stats heading' do
      expect(rendered).to have_content "Stats"
    end

    it 'renders the collapse toggle' do
      expect(rendered).to have_content "Show/Hide"
    end

    it 'renders no stat list items' do
      assert_select "li.list-group-item", count: 0
    end
  end

  context "with stats items" do
    let(:garden) { create(:garden, owner: member) }
    let(:planting) { create(:planting, owner: member) }
    let(:harvest) { create(:harvest, owner: member) }
    let(:seed) { create(:seed, owner: member) }
    let(:post) { create(:post, author: member) }
    let(:job) { create(:job, owner: member) }
    let(:other_member) { create(:member) }
    let(:follower) { create(:member) }

    before do
      member.gardens << garden
      member.plantings << planting
      member.harvests << harvest
      member.seeds << seed
      member.posts << post
      member.jobs << job
      member.followed << Follow.create!(user: member, target: other_member)
      member.followers << Follow.create!(user: follower, target: member)

      render partial: 'members/stats', locals: { member: }
    end

    it 'links to gardens' do
      assert_select "a[href=?]", member_gardens_path(member), text: "1 garden"
    end

    it 'links to plantings' do
      assert_select "a[href=?]", member_plantings_path(member), text: "1 planting"
    end

    it 'links to harvests' do
      assert_select "a[href=?]", member_harvests_path(member), text: "1 harvest"
    end

    it 'links to seeds' do
      assert_select "a[href=?]", member_seeds_path(member), text: "1 seed"
    end

    it 'links to posts' do
      assert_select "a[href=?]", member_posts_path(member), text: "1 post"
    end

    it 'links to jobs' do
      assert_select "a[href=?]", member_jobs_path(member), text: "1 job"
    end

    it 'links to followed' do
      assert_select "a[href=?]", member_follows_path(member), text: "1 follow"
    end

    it 'links to followers with localized string' do
      assert_select "a[href=?]", member_followers_path(member), text: "1 follower"
    end
  end

  context "with multiple followers" do
    let(:follower1) { create(:member) }
    let(:follower2) { create(:member) }

    before do
      member.followers << Follow.create!(user: follower1, target: member)
      member.followers << Follow.create!(user: follower2, target: member)

      render partial: 'members/stats', locals: { member: }
    end

    it 'links to followers with pluralized text' do
      assert_select "a[href=?]", member_followers_path(member), text: "2 followers"
    end
  end
end
