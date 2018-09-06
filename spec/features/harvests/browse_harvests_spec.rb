require 'rails_helper'

feature "browse harvests" do
  let!(:member) { create :member }
  let!(:harvest) { create :harvest, owner: member }

  background { login_as member }
  subject { page }
  feature 'blank optional fields' do
    let!(:harvest) { create :harvest, :no_description }
    before { visit harvests_path }

    scenario 'read more' do
      is_expected.not_to have_link "Read more"
    end
  end

  feature "filled in optional fields" do
    let!(:harvest) { create :harvest, :long_description }

    before(:each) do
      visit harvests_path
    end

    scenario 'read more' do
      is_expected.to have_link "Read more"
    end

    it 'links to #show' do
      is_expected.to have_link harvest.crop.name, href: harvest_path(harvest)
    end
  end
end
