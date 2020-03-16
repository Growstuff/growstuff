# frozen_string_literal: true

require 'rails_helper'
require 'custom_matchers'

describe "Gardens" do
  context 'logged in' do
    subject { page }

    include_context 'signed in member'
    let(:garden) { member.gardens.first }
    let(:other_member_garden) { FactoryBot.create :garden }

    describe '#index' do
      shared_examples "has buttons bar at top" do
        it "has buttons bar at top" do
          within '.layout-nav' do
            expect(subject).to have_link 'Add a garden'
            expect(subject).to have_link 'My gardens'
            expect(subject).to have_link "Everyone's gardens"
          end
        end
      end

      context 'my gardens' do
        before { visit gardens_path(member_slug: member.slug) }

        include_examples "has buttons bar at top"

        context 'with actions menu expanded' do
          before { click_link 'Actions' }
          it "has actions on garden" do
            expect(subject).to have_link 'Plant something here'
            expect(subject).to have_link 'Mark as inactive'
            expect(subject).to have_link 'Edit'
            expect(subject).to have_link 'Add photo'
            expect(subject).to have_link 'Delete'
          end
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
          it { is_expected.not_to have_link 'Actions' }
        end
      end
    end

    describe '#show' do
      describe 'my garden' do
        before { visit garden_path(garden) }

        context 'with actions menu expanded' do
          before { click_link 'Actions' }
          it { is_expected.to have_link 'Edit' }
          it { is_expected.to have_link 'Delete' }
          it { is_expected.to have_content "Plant something here" }
          it { is_expected.to have_content "Add photo" }
        end
      end

      describe "someone else's garden" do
        before { visit garden_path(other_member_garden) }
        it { is_expected.not_to have_link 'Actions' }
      end
    end
  end
end
