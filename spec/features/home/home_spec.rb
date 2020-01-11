# frozen_string_literal: true

require 'rails_helper'

describe "home page", :search do
  subject { page }

  let(:member) { FactoryBot.create :member }

  let(:photo) { FactoryBot.create :photo, owner: member }
  let(:crop) { FactoryBot.create :crop, created_at: 1.day.ago }

  let(:planting) { FactoryBot.create :planting, owner: member, crop: crop }
  let(:seed)    { FactoryBot.create :tradable_seed, owner: member, crop: crop }
  let(:harvest) { FactoryBot.create :harvest, owner: member, crop: crop       }

  let!(:tradable_seed) { FactoryBot.create :tradable_seed, :reindex, finished: false  }
  let!(:finished_seed)   { FactoryBot.create :tradable_seed, :reindex, finished: true }
  let!(:untradable_seed) { FactoryBot.create :untradable_seed, :reindex               }

  before do
    # Add photos, so they can appear on home page
    planting.photos << photo
    seed.photos << photo
    harvest.photos << photo

    Crop.reindex
    Planting.reindex
    Seed.reindex
    Harvest.reindex
    Photo.reindex

    visit root_path
  end

  shared_examples 'shows seeds' do
    it "show tradeable seed" do
      expect(subject).to have_link href: seed_path(tradable_seed)
    end
    it "does not show finished seeds" do
      expect(subject).not_to have_link href: seed_path(finished_seed)
    end
    it "does not show untradable seeds" do
      expect(subject).not_to have_link href: seed_path(untradable_seed)
    end

    it { is_expected.to have_link 'View all seeds »' }
  end

  shared_examples 'show plantings' do
    describe 'shows plantings section' do
      it { expect(subject).to have_text 'Recently Planted' }
      it { expect(subject).to have_link href: planting_path(planting) }
    end
  end

  shared_examples 'show harvests' do
    describe 'shows harvests section' do
      it { expect(subject).to have_text 'Recently Harvested' }
      it { expect(subject).to have_link href: harvest_path(harvest) }
    end
  end

  shared_examples "show crops" do
    describe 'shows crops section' do
      before { crop.reindex }
      it { is_expected.to have_text 'Some of our crops' }
      it { is_expected.to have_link href: crop_path(crop) }
    end

    describe 'shows recently added crops' do
      it { is_expected.to have_text 'Recently Added' }
      it 'link to newest crops' do
        expect(subject).to have_link crop.name, href: crop_path(crop)
      end
    end

    it 'includes a link to all crops' do
      expect(subject).to have_link 'View all crops'
    end
  end

  context 'when anonymous' do
    include_examples 'show crops'
    include_examples 'show plantings'
    include_examples 'show harvests'
    include_examples 'shows seeds'
    it { is_expected.to have_text 'community of food gardeners' }
  end

  context "when signed in" do
    include_context 'signed in member'
    include_examples 'show crops'
    include_examples 'show plantings'
    include_examples 'show harvests'
    include_examples 'shows seeds'

    describe 'should say welcome' do
      before { visit root_path }

      it { expect(page).to have_content "Welcome to #{ENV['GROWSTUFF_SITE_NAME']}, #{member.login_name}" }
    end
  end
end
