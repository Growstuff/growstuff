require 'rails_helper'

feature "member deletion" do

  context "with activity and followers" do
    let(:member) { FactoryGirl.create(:member) }
    let(:other_member) { FactoryGirl.create(:member) }
    let(:memberpost) { FactoryGirl.create(:post, :author => member) }
    let(:othermemberpost) { FactoryGirl.create(:post, :author => other_member) }
    background do
      login_as(member)
      visit member_path(other_member)
      click_link 'Follow'
      logout
      login_as(other_member)
      visit member_path(member)
      click_link 'Follow'
      logout
      FactoryGirl.create_list(:planting, 2, :owner => member)
      FactoryGirl.create_list(:harvest, 3, :owner => member)
      FactoryGirl.create_list(:seed, 4, :owner => member)
      FactoryGirl.create_list(:post, 5, :author => member)
      FactoryGirl.create(:comment, :author => member, :post => othermemberpost)
      FactoryGirl.create(:comment, :author => other_member, :post => memberpost)
    end

    scenario "has option to delete on member profile page" # do
      # visit member_path(member)
      # expect(page).to have_link "Delete account", :href => member_delete_path(member)
    # end
    
    scenario "requests confirmation for deletion"

    scenario "deletes and removes bio" # do
      # member.delete
      # visit member_path(member)
      # expect(page).to have_content "no longer exists"
    # end
    
    context "deletes and" do
      background do
        member.delete
      end
    
      scenario "removes plantings, gardens, harvests and seeds"

      scenario "removes members from following" #do
        #visit member_follows_path(other_member)
        #expect(page).not_to have_content "#{member.login_name}"
        #visit member_followers_path(other_member)
        #expect(page).not_to have_content "#{member.login_name}"
      #end
    
      scenario "replaces posts with deletion note"
      
      scenario "leaves comments from other members on deleted post"
      
      scenario "replaces comments on others' posts with deletion note, leaving post intact"

    end
    
  end
  
  context "for a crop wrangler" do
    let(:member) { FactoryGirl.create(:member, :crop_wrangler => true) }
    let(:crop) { FactoryGirl.create(:crop, 1, :creator => member) }
    
    scenario "leaves crops behind, reassigned to cropbot"
    
  end
  
  context "for an admin" do
    let(:member) { FactoryGirl.create(:member, :admin => true) }
    let(:crop) { FactoryGirl.create(:crop, :creator => member) }
    
    scenario "leaves crops behind, reassigned to cropbot"
    
  end
  
end
