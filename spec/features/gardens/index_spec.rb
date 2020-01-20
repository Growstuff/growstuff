# frozen_string_literal: true

require 'rails_helper'
require 'custom_matchers'

describe "Gardens#index", :js do
  context "Logged in as member" do
    include_context 'signed in member'
    let(:member) { FactoryBot.create :member, login_name: 'shadow' }

    context "with 10 gardens" do
      before do
        FactoryBot.create_list :garden, 10, owner: member
        visit member_gardens_path(member_slug: member.slug)
      end

      it "displays each of the gardens" do
        member.gardens.each do |garden|
          expect(page).to have_text garden.name
        end
      end
      it "links to each garden" do
        member.gardens.each do |garden|
          expect(page).to have_link(garden.name, href: garden_path(garden))
        end
      end
    end

    context "with inactive gardens" do
      let!(:active_garden) { FactoryBot.create :garden, name: "My active garden", owner: member }
      let!(:inactive_garden) { FactoryBot.create :inactive_garden, name: "retired garden", owner: member }

      before { visit member_gardens_path(member_slug: member.slug) }

      it "show active garden" do
        expect(page).to have_text active_garden.name
      end
      it "does not show inactive garden" do
        expect(page).not_to have_text inactive_garden.name
      end
      it "links to active garden" do
        expect(page).to have_link(active_garden.name, href: garden_path(active_garden))
      end
      it "does not link to inactive gardens" do
        expect(page).not_to have_link(inactive_garden.name, href: garden_path(inactive_garden))
      end
    end

    context 'with plantings' do
      let(:maize) { FactoryBot.create(:maize) }
      let(:tomato) { FactoryBot.create(:tomato) }

      let!(:planting) do
        FactoryBot.create :planting, owner: member, crop: maize, garden: member.gardens.first
      end
      let!(:finished_planting) do
        FactoryBot.create :finished_planting, owner: member, crop: tomato, garden: member.gardens.first
      end

      before do
        visit member_gardens_path(member_slug: member.slug)
      end

      it "shows planting in garden" do
        expect(page).to have_link(planting.crop.name, href: planting_path(planting))
      end
      it "does not show finished planting" do
        expect(page).not_to have_text(finished_planting.crop.name)
      end
    end
  end

  describe 'badges' do
    let(:garden) { member.gardens.first }
    let(:member) { FactoryBot.create :member, login_name: 'robbieburns' }
    let(:crop)   { FactoryBot.create :crop                              }

    before do
      # time to harvest = 50 day
      # time to finished = 90 days
      FactoryBot.create(:harvest,
                        harvested_at: 50.days.ago,
                        crop:         crop,
                        planting:     FactoryBot.create(:planting,
                                                        crop:        crop,
                                                        planted_at:  100.days.ago,
                                                        finished_at: 10.days.ago))
      crop.plantings.each(&:update_harvest_days!)
      crop.update_lifespan_medians
      crop.update_harvest_medians

      garden.update! name: 'super awesome garden'
      assert planting
      visit member_gardens_path(member_slug: member.slug)
    end

    describe 'harvest still growing' do
      let!(:planting) do
        FactoryBot.create :planting,
                          crop:       crop,
                          owner:      member,
                          garden:     garden,
                          planted_at: Time.zone.today
      end

      it { expect(page).to have_link href: planting_path(planting) }
      it { expect(page).to have_link href: garden_path(planting.garden) }
      it { expect(page).to have_text '7 weeks' }
      it { expect(page).not_to have_text 'harvesting now' }
    end

    describe 'harvesting now' do
      let!(:planting) do
        FactoryBot.create :planting,
                          crop: crop,
                          owner: member, garden: garden,
                          planted_at: 51.days.ago
      end

      it { expect(crop.median_days_to_first_harvest).to eq 50 }
      it { expect(crop.median_lifespan).to eq 90 }

      it { expect(page).to have_text 'harvesting now' }
      it { expect(page).not_to have_text 'Predicted weeks until harvest' }
    end

    describe 'super late' do
      let!(:planting) do
        FactoryBot.create :planting,
                          crop: crop, owner: member,
                          garden: garden, planted_at: 260.days.ago
      end

      it { expect(page).to have_text 'super late' }
      it { expect(page).not_to have_text 'harvesting now' }
      it { expect(page).not_to have_text 'Predicted weeks until harvest' }
      it { expect(page).not_to have_text 'Predicted weeks until planting is finished' }
    end
  end
end
