require 'rails_helper'

describe "seeds", js: true do
  context "signed in user" do
    include_context 'signed in member'
    xit "button on index to edit seed" do
      let!(:seed) { create :seed, owner: member }

      before do
        visit seeds_path
        click_link 'Actions'
        click_link "Edit"
      end

      it { expect(current_path).to eq edit_seed_path(seed) }
      it { expect(page).to have_content 'Editing seeds' }
    end

    describe "button on front page to add seeds" do
      before do
        visit root_path
        click_link 'Record'
        click_link(href: new_seed_path)
      end

      it { expect(current_path).to eq new_seed_path }
      it { expect(page).to have_content 'Save seeds' }
    end

    describe "Clicking link to owner's profile" do
      before do
        visit member_seeds_path(member)
        click_link "View Owners Profile"
      end

      it { expect(current_path).to eq member_path(member) }
    end

    # actually adding seeds is in spec/features/seeds_new_spec.rb

    it "edit seeds" do
      seed = create :seed, owner: member
      visit seed_path(seed)
      click_link 'Actions'
      click_link 'Edit'
      expect(current_path).to eq edit_seed_path(seed)
      fill_in 'Quantity', with: seed.quantity * 2
      click_button 'Save'
      expect(current_path).to eq seed_path(seed)
    end

    describe "delete seeds" do
      let(:seed) { FactoryBot.create :seed, owner: member }

      before do
        visit seed_path(seed)
        click_link 'Actions'
        accept_confirm do
          click_link 'Delete'
        end
      end

      it { expect(current_path).to eq seeds_path }
    end

    describe '#show' do
      before { visit seed_path(seed) }

      describe "view seeds with max and min days until maturity" do
        let(:seed) { FactoryBot.create :seed, days_until_maturity_min: 5, days_until_maturity_max: 7 }

        it { expect(find('.seedfacts--maturity')).to have_content("5–7") }
      end

      describe "view seeds with only max days until maturity" do
        let(:seed) { FactoryBot.create :seed, days_until_maturity_max: 7 }

        it { expect(find('.seedfacts--maturity')).to have_content("7") }
      end

      describe "view seeds with only min days until maturity" do
        let(:seed) { FactoryBot.create :seed, days_until_maturity_min: 5 }

        it { expect(find('.seedfacts--maturity')).to have_content("5") }
      end

      describe "view seeds with neither max nor min days until maturity" do
        let(:seed) { FactoryBot.create :seed }

        it { expect(find('.seedfacts--maturity')).to have_content "unknown" }
      end
    end
  end
end
