# frozen_string_literal: true

require 'rails_helper'

describe "member profile", js: true do
  let(:member) { create :member }
  let(:other_member)  { create :member                }
  let(:admin_member)  { create :admin_member          }
  let(:crop_wrangler) { create :crop_wrangling_member }

  shared_examples 'member details' do
    it "basic details on member profile page" do
      visit member_path(member)
      expect(page).to have_content("All about #{member.login_name}")
      expect(page).to have_content member.bio
      expect(page).to have_content "Member since #{member.created_at.to_s(:date)}"
    end

    it "gravatar" do
      visit member_path(member)
      expect(page).to have_css "img.avatar"
    end

    context "location" do
      it "member has set location" do
        london_member = create :london_member
        visit member_path(london_member)
        expect(page).to have_content(london_member.location)
        expect(page).to have_css("#membermap")
        expect(page).to have_content "See other members, plantings, seeds and more near #{london_member.location}"
      end

      it "member has not set location" do
        visit member_path(member)
        expect(page).not_to have_css("h1>small")
        expect(page).not_to have_css("#membermap")
        expect(page).not_to have_content "See other members"
      end
    end

    context "email privacy" do
      it "public email address" do
        public_member = create :public_member
        visit member_path(public_member)
        expect(page).to have_content public_member.email
      end
      it "private email address" do
        visit member_path(member)
        expect(page).not_to have_content member.email
      end
    end

    context "activity stats" do
      it "with no activity" do
        visit member_path(member)
        expect(page).to have_content "Activity"
        expect(page).to have_content "0 plantings"
        expect(page).to have_content "0 harvests"
        expect(page).to have_content "0 seeds"
        expect(page).to have_content "0 posts"
      end

      context "with some activity" do
        let!(:planting) { FactoryBot.create :planting, owner: member }
        let!(:harvest) { FactoryBot.create :harvest, owner: member }
        let!(:seed) { FactoryBot.create :seed, owner: member }
        let!(:post) { FactoryBot.create :post, author: member }
        before { visit member_path(member) }
        it { expect(page).to have_link(href: planting_path(planting)) }
        it { expect(page).to have_link(href: harvest_path(harvest)) }
        it { expect(page).to have_link(href: seed_path(seed)) }
        it { expect(page).to have_link(href: post_path(post)) }
      end
    end

    it "twitter link" do
      twitter_auth = create :authentication, member: member
      visit member_path(member)
      expect(page).to have_link twitter_auth.name, href: "https://twitter.com/#{twitter_auth.name}"
    end

    it "flickr link" do
      flickr_auth = create :flickr_authentication, member: member
      visit member_path(member)
      expect(page).to have_link flickr_auth.name, href: "https://flickr.com/photos/#{flickr_auth.uid}"
    end

    describe 'user role labels' do
      describe "admin user's page" do
        before { visit member_path(admin_member) }
        it { expect(page).to have_text "Admin" }
      end

      it "crop wrangler's page" do
        visit member_path(crop_wrangler)
        expect(page).to have_text "Crop Wrangler"
      end

      it "ordinary user's page" do
        visit member_path(other_member)
        expect(page).not_to have_text "Crop Wrangler"
        expect(page).not_to have_text "Admin"
      end
    end
  end

  shared_examples 'member activity' do
    context 'member has plantings' do
      let!(:new_planting) { FactoryBot.create :planting, owner: member, planted_at: Time.zone.now }
      let!(:old_planting) { FactoryBot.create :planting, owner: member, planted_at: 3.years.ago }
      let!(:finished_planting) { FactoryBot.create :finished_planting, owner: member }
      let!(:no_planted_at_planting) { FactoryBot.create :planting, owner: member, planted_at: nil }
      before { visit member_path(member) }
      it { expect(page).to have_link href: planting_path(new_planting) }
      it { expect(page).to have_link href: planting_path(old_planting) }
      it { expect(page).to have_link href: planting_path(finished_planting) }
      it { expect(page).not_to have_link href: planting_path(no_planted_at_planting) }
    end

    context 'member has seeds' do
      let!(:seed) { FactoryBot.create :seed, owner: member }
      before { visit member_path(member) }
      it { expect(page).to have_link href: seed_path(seed) }
    end

    context 'member has harvests' do
      let!(:harvest) { FactoryBot.create :harvest, owner: member }
      before { visit member_path(member) }
      it { expect(page).to have_link href: harvest_path(harvest) }
    end

    context 'member has posts' do
      let!(:post) { FactoryBot.create :post, author: member }
      before { visit member_path(member) }
      it { expect(page).to have_link href: post_path(post) }
    end

    context 'member has comments' do
      let(:post) { FactoryBot.create :post }
      let!(:comment) { FactoryBot.create :comment, post: post, author: member }
      before { visit member_path(member) }
      it { expect(page).to have_link href: post_path(post) }
      it { expect(page).to have_link href: comment_path(comment) }
    end

    context 'photos' do
      let(:planting) { FactoryBot.create :planting, owner: member }
      let!(:photo) { FactoryBot.create :photo, owner: member, plantings: [planting] }
      before { visit member_path(member) }
      it { expect(page).to have_link href: photo_path(photo) }
      it { expect(page).to have_link href: planting_path(planting) }
    end

    context 'plantings' do
      let(:crop) { FactoryBot.create :crop }
      before do
        # time to harvest = 50 day
        # time to finished = 90 days
        FactoryBot.create(:harvest,
                          harvested_at: 50.days.ago,
                          crop:         crop,
                          planting:     FactoryBot.create(:planting,
                                                          crop:        crop,
                                                          planted_at:  100.days.ago,
                                                          finished_at: 10.days.ago))
        crop.plantings.each(&:update_harvest_days!)
        crop.update_lifespan_medians
        crop.update_harvest_medians

        growing_planting
        harvesting_planting
        super_late_planting

        visit member_path(member)
      end

      let(:growing_planting) do
        FactoryBot.create :planting,
                          crop:       crop,
                          owner:      member,
                          planted_at: Time.zone.today
      end

      let(:harvesting_planting) do
        FactoryBot.create :planting,
                          crop:       crop,
                          owner:      member,
                          planted_at: 51.days.ago
      end

      let(:super_late_planting) do
        FactoryBot.create :planting,
                          crop: crop, owner: member,
                          planted_at: 260.days.ago
      end

      it { expect(page).to have_link(href: planting_path(growing_planting)) }
      it { expect(page).to have_link(href: planting_path(harvesting_planting)) }
      it { expect(page).to have_link(href: planting_path(super_late_planting)) }
    end
  end

  context "not signed in" do
    include_examples 'member details'
    include_examples 'member activity'

    it "no bio" do
      member.update! bio: nil
      visit member_path(member)
      expect(page).to have_content "hasn't written a bio yet"
    end
  end

  context "signed in member" do
    include_context 'signed in member'
    include_examples 'member details'
    include_examples 'member activity'

    context "your own profile page" do
      before { visit member_path(member) }

      it "has a button to edit profile" do
        expect(page).to have_link "Edit profile", href: edit_member_registration_path
      end
    end

    context "someone else's profile page" do
      before { visit member_path(other_member) }

      it "has a private message button" do
        expect(page).to have_link "Send message", href: new_message_path(recipient_id: other_member.id)
      end
      it { expect(page).not_to have_link "Edit profile", href: edit_member_registration_path }
    end
  end
end
