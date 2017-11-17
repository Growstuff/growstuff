## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project
## We no longer write new view and controller tests, but instead write
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara).
## These test the full stack, behaving as a browser, and require less complicated setup
## to run. Please feel free to delete old view/controller tests as they are reimplemented
## in feature tests.
##
## If you submit a pull request containing new view or controller tests, it will not be
## merged.

require 'rails_helper'

describe "harvests/show" do
  let!(:harvest) { FactoryBot.create(:harvest) }

  before do
    controller.stub(:current_user) { nil }
    assign(:harvest, harvest)
    render
  end

  subject { render }

  describe "renders attributes" do
    it { is_expected.to have_content harvest.crop.name }
    it { is_expected.to have_content harvest.harvested_at.to_s }
    it { is_expected.to have_content harvest.plant_part.to_s }
  end
end
