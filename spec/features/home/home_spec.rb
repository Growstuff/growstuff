# frozen_string_literal: true

require 'rails_helper'

describe "home page" do
  subject { page }

  let(:member) { create(:member) }

  let(:photo) { create(:photo, owner: member) }
  let(:crop) { create(:crop, created_at: 1.day.ago) }

  let(:planting) { create(:planting, owner: member, crop:) }
  let(:seed)    { create(:tradable_seed, owner: member, crop:) }
  let(:harvest) { create(:harvest, owner: member, crop:)       }

  let!(:tradable_seed) { create(:tradable_seed, finished: false)  }
  let!(:finished_seed)   { create(:tradable_seed, finished: true) }
  let!(:untradable_seed) { create(:untradable_seed)               }

  before do
    # Add photos, so they can appear on home page
    planting.photos << photo
    seed.photos << photo
    harvest.photos << photo

    Crop.reindex

    visit root_path
  end

  shared_examples 'shows seeds' do
    it "show tradeable seed" do
      expect(subject).to have_link href: seed_path(tradable_seed)
    end

    it "does not show finished seeds" do
      expect(subject).to have_no_link href: seed_path(finished_seed)
    end

    it "does not show untradable seeds" do
      expect(subject).to have_no_link href: seed_path(untradable_seed)
    end
  end

  shared_examples 'show plantings' do
    it { expect(subject).to have_link href: planting_path(planting) }
  end

  shared_examples 'omits sections that are not in the designs' do
    it { is_expected.to have_no_text 'Some of our crops' }
    it { is_expected.to have_no_text 'Recently Harvested' }
    it { is_expected.to have_no_text 'Want to install Growstuff on your phone?' }
  end

  context 'when anonymous' do
    describe 'recent posts' do
      let!(:post) { create(:post, subject: 'What are you sowing?') }

      before { visit root_path }

      it { is_expected.to have_link 'What are you sowing?', href: post_path(post) }
      it { is_expected.to have_css '.home-post-card .home-post-photo img' }
    end

    it_behaves_like 'show plantings'
    it_behaves_like 'shows seeds'
    it_behaves_like 'omits sections that are not in the designs'
    it_behaves_like 'is accessible'
    it { is_expected.to have_text 'community of food gardeners' }
    it { is_expected.to have_text 'Planted this week' }
    it { is_expected.to have_text 'Why sign in' }
    it { is_expected.to have_link 'Join free', href: new_member_registration_path }
  end

  context "when signed in" do
    include_context 'signed in member'
    it_behaves_like 'show plantings'
    it_behaves_like 'shows seeds'
    it_behaves_like 'omits sections that are not in the designs'
    it_behaves_like 'is accessible'

    describe 'a member who has planted before' do
      before do
        create(:planting, owner: member, garden: member.gardens.first, planted_at: 2.years.ago)
        visit root_path
      end

      it { expect(page).to have_content "#{member.login_name}'s garden" }
      it { expect(page).to have_content 'Harvest by month' }
    end

    describe 'stat tiles' do
      before do
        create(:planting, owner: member, garden: member.gardens.first, planted_at: 2.years.ago)
        visit root_path
      end

      it 'links the ready tile to the growing now section' do
        expect(page).to have_link 'to harvest this week', href: '#growing-now'
      end

      it 'has a growing now section to link to' do
        expect(page).to have_css 'section#growing-now'
      end

      it 'does not link the plantings tile' do
        expect(page).to have_no_link 'plantings this year'
      end
    end

    describe 'a member on their first visit' do
      before do
        member.plantings.destroy_all
        member.update_columns(location: nil, latitude: nil, longitude: nil)
        visit root_path
      end

      it 'can set where they garden in a dialog' do
        expect(page).to have_css('[data-react-component="LocationPicker"]', visible: :all)
      end

      it 'can plant their first crop in a dialog' do
        expect(page).to have_css('[data-react-component="PlantPicker"]', visible: :all)
      end
    end

    describe 'recent posts' do
      before do
        create(:post, subject: 'Slugs in spring')
        visit root_path
      end

      it { is_expected.to have_link 'Slugs in spring' }
      it { is_expected.to have_css '.home-post-card .home-post-photo img' }
    end

    describe 'a member in their first year' do
      before do
        create(:planting, owner: member, garden: member.gardens.first, planted_at: 1.month.ago)
        visit root_path
      end

      it 'can plant, harvest, save seeds and add a photo in dialogs' do
        pickers = %w[PlantPicker PlantingPicker PhotoPicker].map { |name| "[data-react-component=\"#{name}\"]" }
        expect(page).to have_css(pickers.join(', '), minimum: 4, visible: :all)
      end
    end

    describe 'should say welcome' do
      before do
        member.plantings.destroy_all
        visit root_path
      end

      it { expect(page).to have_content "Welcome to #{ENV.fetch('GROWSTUFF_SITE_NAME', nil)}, #{member.login_name}" }
    end
  end
end
