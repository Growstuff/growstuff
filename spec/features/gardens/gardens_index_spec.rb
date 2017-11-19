require 'rails_helper'
require 'custom_matchers'

feature "Gardens#index", :js do
  context "Logged in as member" do
    let(:member) { FactoryBot.create :member }

    background { login_as member }

    context "with 10 gardens" do
      before do
        FactoryBot.create_list :garden, 10, owner: member
        visit gardens_path(member: member)
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

      before { visit gardens_path(member: member) }

      it "show active garden" do
        expect(page).to have_text active_garden.name
      end
      it "should not show inactive garden" do
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
        visit gardens_path(member: member)
      end
      it "shows planting in garden" do
        expect(page).to have_link(planting.crop.name, href: planting_path(planting))
      end
      it "does not show finished planting" do
        expect(page).not_to have_text(finished_planting.crop.name)
      end
    end
  end
end
