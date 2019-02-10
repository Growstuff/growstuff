require 'rails_helper'

describe "browse harvests" do
  subject { page }

  let!(:member) { create :member }
  let!(:harvest) { create :harvest, owner: member }

  before { login_as member }

  describe 'blank optional fields' do
    let!(:harvest) { create :harvest, :no_description }

    before { visit harvests_path }

    it 'read more' do
      is_expected.not_to have_link "Read more"
    end
  end

  describe "filled in optional fields" do
    let!(:harvest) { create :harvest, :long_description }

    before(:each) do
      visit harvests_path
    end

    it 'read more' do
      is_expected.to have_link "Read more"
    end

    it 'links to #show' do
      is_expected.to have_link harvest.crop.name, href: harvest_path(harvest)
    end
  end
end
