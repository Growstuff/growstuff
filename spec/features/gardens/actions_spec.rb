require 'rails_helper'
require 'custom_matchers'

feature "Gardens" do
  context 'logged in' do
    subject { page }

    let(:member) { FactoryBot.create :member }
    background { login_as member }

    let(:garden) { member.gardens.first }
    let(:other_member_garden) { FactoryBot.create :garden }

    describe '#index' do
      shared_examples "has buttons bar at top" do
        it "has buttons bar at top" do
          within '.layout-actions' do
            is_expected.to have_link 'Add a garden'
            is_expected.to have_link 'My Gardens'
            is_expected.to have_link "Everyone's gardens"
          end
        end
      end

      context 'my gardens' do
        before { visit gardens_path(owner: member) }

        include_examples "has buttons bar at top"
        it "has actions on garden" do
          is_expected.to have_link 'Plant something here'
          is_expected.to have_link 'Mark as inactive'
          is_expected.to have_link 'Edit'
          is_expected.to have_link 'Add photo'
          is_expected.to have_link 'Delete'
        end
      end

      context 'all gardens' do
        before { visit gardens_path }

        include_examples "has buttons bar at top"
      end

      context "other member's garden" do
        before { visit gardens_path(owner: FactoryBot.create(:member)) }

        include_examples "has buttons bar at top"
        describe 'does not show actions on other member garden' do
          it { is_expected.not_to have_link 'Edit' }
          it { is_expected.not_to have_link 'Delete' }
        end
      end
    end

    describe '#show' do
      describe 'my garden' do
        before { visit garden_path(garden) }
        it { is_expected.to have_link 'Edit' }
        it { is_expected.to have_link 'Delete' }
        it { is_expected.to have_content "Plant something here" }
        it { is_expected.to have_content "Add photo" }
      end
      describe "someone else's garden" do
        before { visit garden_path(other_member_garden) }
        it { is_expected.not_to have_link 'Edit' }
        it { is_expected.not_to have_link 'Delete' }
        it { is_expected.not_to have_content "Plant something here" }
        it { is_expected.not_to have_content "Add photo" }
      end
    end
  end

  # background do
  #   login_as member
  #   visit new_garden_path
  # end

  # it "has the required fields help text" do
  #   expect(page).to have_content "* denotes a required field"
  # end

  # it "displays required and optional fields properly" do
  #   expect(page).to have_selector ".form-group.required", text: "Name"
  #   expect(page).to have_optional 'textarea#garden_description'
  #   expect(page).to have_optional 'input#garden_location'
  #   expect(page).to have_optional 'input#garden_area'
  # end

  # scenario "Create new garden" do
  #   fill_in "Name", with: "New garden"
  #   click_button "Save"
  #   expect(page).to have_content "Garden was successfully created"
  #   expect(page).to have_content "New garden"
  # end

  # scenario "Refuse to create new garden with negative area" do
  #   visit new_garden_path
  #   fill_in "Name", with: "Negative Garden"
  #   fill_in "Area", with: -5
  #   click_button "Save"
  #   expect(page).not_to have_content "Garden was successfully created"
  #   expect(page).to have_content "Area must be greater than or equal to 0"
  # end
end
