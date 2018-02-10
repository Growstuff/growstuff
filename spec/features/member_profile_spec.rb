require 'rails_helper'

feature "member profile", js: true do
  context "signed out member" do
    let(:member) { create :member }

    scenario "basic details on member profile page" do
      visit member_path(member)
      expect(page).to have_css("h1", text: member.login_name)
      expect(page).to have_content member.bio
      expect(page).to have_content "Member since: #{member.created_at.to_s(:date)}"
      expect(page).to have_content "#{member.login_name}'s gardens"
      expect(page).to have_link "More about this garden...", href: garden_path(member.gardens.first)
    end

    scenario "no bio" do
      member.bio = nil
      member.save
      visit member_path(member)
      expect(page).to have_content "hasn't written a bio yet"
    end

    scenario "gravatar" do
      visit member_path(member)
      expect(page).to have_css "img.avatar"
    end

    context "location" do
      scenario "member has set location" do
        london_member = create :london_member
        visit member_path(london_member)
        expect(page).to have_css("h1>small", text: london_member.location)
        expect(page).to have_css("#membermap")
        expect(page).to have_content "See other members, plantings, seeds and more near #{london_member.location}"
      end

      scenario "member has not set location" do
        visit member_path(member)
        expect(page).not_to have_css("h1>small")
        expect(page).not_to have_css("#membermap")
        expect(page).not_to have_content "See other members"
      end
    end

    context "email privacy" do
      scenario "public email address" do
        public_member = create :public_member
        visit member_path(public_member)
        expect(page).to have_content public_member.email
      end
      scenario "private email address" do
        visit member_path(member)
        expect(page).not_to have_content member.email
      end
    end

    context "email privacy" do
      scenario "public email address" do
        public_member = create :public_member
        visit member_path(public_member)
        expect(page).to have_content public_member.email
      end
      scenario "private email address" do
        visit member_path(member)
        expect(page).not_to have_content member.email
      end
    end

    context "activity stats" do
      scenario "with no activity" do
        visit member_path(member)
        expect(page).to have_content "Activity"
        expect(page).to have_content "0 plantings"
        expect(page).to have_content "0 harvests"
        expect(page).to have_content "0 seeds"
        expect(page).to have_content "0 posts"
      end

      scenario "with some activity" do
        create_list :planting, 2, owner: member
        create_list :harvest, 3, owner: member
        create_list :seed, 4, owner: member
        create_list :post, 5, author: member
        visit member_path(member)
        expect(page).to have_link "2 plantings", href: plantings_by_owner_path(owner: member)
        expect(page).to have_link "3 harvests", href: harvests_by_owner_path(owner: member)
        expect(page).to have_link "4 seeds", href: seeds_by_owner_path(owner: member)
        expect(page).to have_link "5 posts", href: posts_by_author_path(author: member)
      end
    end

    scenario "twitter link" do
      twitter_auth = create :authentication, member: member
      visit member_path(member)
      expect(page).to have_link twitter_auth.name, href: "http://twitter.com/#{twitter_auth.name}"
    end

    scenario "flickr link" do
      flickr_auth = create :flickr_authentication, member: member
      visit member_path(member)
      expect(page).to have_link flickr_auth.name, href: "http://flickr.com/photos/#{flickr_auth.uid}"
    end
  end

  context "signed in member" do
    let(:member) { create :member }
    let(:other_member) { create :member }
    let(:admin_member) { create :admin_member }
    let(:crop_wrangler) { create :crop_wrangling_member }

    background do
      login_as(member)
    end

    scenario "admin user's page" do
      visit member_path(admin_member)
      expect(page).to have_text "Admin"
    end

    scenario "crop wrangler's page" do
      visit member_path(crop_wrangler)
      expect(page).to have_text "Crop Wrangler"
    end

    scenario "ordinary user's page" do
      visit member_path(other_member)
      expect(page).not_to have_text "Crop Wrangler"
      expect(page).not_to have_text "Admin"
    end

    context "your own profile page" do
      background do
        visit member_path(member)
      end

      scenario "has a link to create new garden" do
        expect(page).to have_link "New Garden", href: new_garden_path
      end

      scenario "has a button to edit profile" do
        expect(page).to have_link "Edit profile", href: edit_member_registration_path
      end
    end

    context "someone else's profile page" do
      background do
        visit member_path(other_member)
      end

      scenario "has a private message button" do
        expect(page).to have_link "Send message", href: new_notification_path(recipient_id: other_member.id)
      end
    end

    context "home page" do
      background do
        visit root_path
      end

      scenario "does not have a button to edit profile" do
        expect(page).not_to have_link "Edit profile", href: edit_member_registration_path
      end
    end
  end
end
