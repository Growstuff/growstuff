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

    describe 'should say welcome' do
      before { visit root_path }

      it { expect(page).to have_content "Welcome to #{ENV.fetch('GROWSTUFF_SITE_NAME', nil)}, #{member.login_name}" }
    end
  end
end
