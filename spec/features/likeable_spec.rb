require 'rails_helper'

describe 'Likeable', js: true do
  let(:member)         { FactoryBot.create(:member)        }
  let(:another_member) { FactoryBot.create(:london_member) }
  let(:post)           { FactoryBot.create(:post)          }

  context 'logged in member' do
    before { login_as member }

    describe 'posts' do
      before { visit post_path(post) }
      it 'can be liked' do
        expect(page).to have_link 'Like'
        click_link 'Like'
        expect(page).to have_css(".like-count", text: "1")

        visit post_path(post)

        expect(page).to have_link 'Unlike'
        click_link 'Unlike'
        expect(page).to have_css(".like-count", text: "0")
      end

      it 'displays correct number of likes' do
        expect(page).to have_link 'Like'
        click_link 'Like'
        expect(page).to have_css(".like-count", text: "1")

        logout(member)
        login_as(another_member)
        visit post_path(post)

        expect(page).to have_link 'Like'
        click_link 'Like'
        expect(page).to have_css(".like-count", text: "2")
      end
    end
  end
end
