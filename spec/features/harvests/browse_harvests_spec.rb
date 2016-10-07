require 'rails_helper'

feature "browse harvests" do
  let!(:member) { create :member }
  let!(:harvest) { create :harvest, owner: member }

  background do
    login_as member
  end

  feature 'blank optional fields' do
    let!(:harvest) { create :harvest, :no_description }

    before (:each) do
      visit harvests_path
    end

    scenario 'read more' do
      expect(page).not_to have_link "Read more"
    end

  end

  feature "filled in optional fields" do
    let!(:harvest) { create :harvest, :long_description }

    before (:each) do
      visit harvests_path
    end

    scenario 'read more' do
      expect(page).to have_link "Read more"
    end

    it 'links to #show' do
      expect(page).to have_link harvest.crop.name, href: harvest_path(harvest)
    end
  end
end
