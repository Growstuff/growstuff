require 'rails_helper'

feature "seeds", js: true do
  context "signed in user" do
    let(:member) { create :member }
    let(:crop) { create :crop }

    background { login_as member }

    scenario "button on index to edit seed" do
      seed = create :seed, owner: member
      visit seeds_path
      click_link "edit_seed_glyphicon"
      expect(current_path).to eq edit_seed_path(seed)
      expect(page).to have_content 'Editing seeds'
    end

    scenario "button on front page to add seeds" do
      visit root_path
      click_link "Add seeds"
      expect(current_path).to eq new_seed_path
      expect(page).to have_content 'Add seeds'
    end

    scenario "Clicking link to owner's profile" do
      visit seeds_by_owner_path(member)
      click_link "View #{member}'s profile >>"
      expect(current_path).to eq member_path(member)
    end

    # actually adding seeds is in spec/features/seeds_new_spec.rb

    scenario "edit seeds" do
      seed = create :seed, owner: member
      visit seed_path(seed)
      click_link 'Edit'
      expect(current_path).to eq edit_seed_path(seed)
      fill_in 'Quantity:', with: seed.quantity * 2
      click_button 'Save'
      expect(current_path).to eq seed_path(seed)
    end

    scenario "delete seeds" do
      seed = create :seed, owner: member
      visit seed_path(seed)
      click_link 'Delete'
      expect(current_path).to eq seeds_path
    end

    scenario "view seeds with max and min days until maturity" do
      seed = create :seed, days_until_maturity_min: 5, days_until_maturity_max: 7
      visit seed_path(seed)
      expect(page).to have_content "Days until maturity: 5–7"
    end

    scenario "view seeds with only max days until maturity" do
      seed = create :seed, days_until_maturity_max: 7
      visit seed_path(seed)
      expect(page).to have_content "Days until maturity: 7"
    end

    scenario "view seeds with only min days until maturity" do
      seed = create :seed, days_until_maturity_min: 5
      visit seed_path(seed)
      expect(page).to have_content "Days until maturity: 5"
    end

    scenario "view seeds with neither max nor min days until maturity" do
      seed = create :seed
      visit seed_path(seed)
      expect(page).to have_content "Days until maturity: unknown"
    end
  end
end
