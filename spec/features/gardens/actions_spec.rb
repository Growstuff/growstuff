require 'rails_helper'
require 'custom_matchers'

describe "Gardens" do
  context 'logged in' do
    subject { page }

    let(:member) { FactoryBot.create :member }
    before { login_as member }

    let(:garden) { member.gardens.first }
    let(:other_member_garden) { FactoryBot.create :garden }

    describe '#index' do
      shared_examples "has buttons bar at top" do
        it "has buttons bar at top" do
          within '.layout-actions' do
            is_expected.to have_link 'Add a garden'
            is_expected.to have_link 'My gardens'
            is_expected.to have_link "Everyone's gardens"
          end
        end
      end

      context 'my gardens' do
        before { visit gardens_path(member_slug: member.slug) }

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
        before { visit gardens_path(member_slug: FactoryBot.create(:member).slug) }

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
end
