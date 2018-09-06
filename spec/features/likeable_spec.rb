require 'rails_helper'

feature 'Likeable', js: true do
  let(:member) { FactoryBot.create(:member) }
  let(:another_member) { FactoryBot.create(:london_member) }
  let(:post) { FactoryBot.create(:post) }

  context 'logged in member' do
    background do
      login_as member
      visit post_path(post)
    end

    scenario 'can be liked' do
      expect(page).to have_link 'Like'
      click_link 'Like'
      expect(page).to have_content '1 like'

      visit post_path(post)

      expect(page).to have_link 'Unlike'
      click_link 'Unlike'
      expect(page).to have_content '0 likes'
    end

    scenario 'displays correct number of likes' do
      expect(page).to have_link 'Like'
      click_link 'Like'
      expect(page).to have_content '1 like'
      logout(member)

      login_as(another_member)
      visit post_path(post)

      expect(page).to have_link 'Like'
      click_link 'Like'
      expect(page).to have_content '2 likes'
    end
  end
end
