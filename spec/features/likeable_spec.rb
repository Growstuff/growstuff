require 'rails_helper'

feature 'Likeable', :js => true do
  let(:member) { FactoryGirl.create(:member) }
  let(:another_member) { FactoryGirl.create(:london_member)}
  let(:post) { FactoryGirl.create(:post) }

  context 'logged in member' do

    background do
      login_as member
      visit post_path(post)
    end

    scenario 'can be liked then unliked' do
      click_link 'Like'
      expect(page).to have_link 'Unlike'
      expect(page).to have_content '1 like'
      click_link 'Unlike'
      expect(page).to have_link 'Like'
    end

    scenario 'displays correct number of likes' do
      click_link 'Like'
      expect(page).to have_content '1 like'
      logout(member)
      login_as(another_member)
      visit post_path(post)
      click_link 'Like'
      expect(page).to have_content '2 likes'
    end

  end

end