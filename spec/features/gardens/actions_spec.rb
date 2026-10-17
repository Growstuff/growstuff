# frozen_string_literal: true

require 'rails_helper'
require 'custom_matchers'

describe "Gardens" do
  context 'logged in' do
    subject { page }

    include_context 'signed in member'
    let(:garden) { member.gardens.first }
    let(:other_member_garden) { create(:garden) }

    describe '#index' do
      context 'my gardens' do
        before { visit gardens_path(member_slug: member.slug) }

        it 'offers to add a garden' do
          expect(subject).to have_button 'Add a garden'
        end

        context 'with actions menu expanded' do
          before { click_link "Actions for #{garden.name}" }

          it "has actions on garden" do
            expect(subject).to have_link 'Mark as inactive'
            expect(subject).to have_link 'Edit'
            expect(subject).to have_link 'Add photo'
            expect(subject).to have_link 'Delete'
          end
        end

        it 'can add a planting' do
          expect(subject).to have_link 'Add planting'
        end
      end

      context "other member's garden" do
        before { visit gardens_path(member_slug: create(:member).slug) }

        it { is_expected.to have_no_button 'Add a garden' }

        describe 'does not show actions on other member garden' do
          it { is_expected.to have_no_link 'Actions' }
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
          it { is_expected.to have_link "Plant something here" }
          it { is_expected.to have_link "Add photo" }
        end
      end

      describe "someone else's garden" do
        before { visit garden_path(other_member_garden) }

        it { is_expected.to have_no_link 'Actions' }
      end
    end
  end
end
