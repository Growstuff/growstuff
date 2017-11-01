## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project.
## We no longer write new view and controller tests, but instead write
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara).
## These test the full stack, behaving as a browser, and require less complicated setup
## to run. Please feel free to delete old view/controller tests as they are reimplemented
## in feature tests.
##
## If you submit a pull request containing new view or controller tests, it will not be
## merged.

require 'rails_helper'

describe "plantings/_form" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @member = FactoryBot.create(:member)
    @garden = FactoryBot.create(:garden, owner: @member)
    @uppercase = FactoryBot.create(:uppercasecrop)
    @lowercase = FactoryBot.create(:lowercasecrop)
    @crop = @lowercase # needed to render the form

    @planting = FactoryBot.create(:planting,
      garden: @garden,
      crop: @crop,
      planted_at: Date.new(2013, 3, 1))
    render
  end

  it "has a free-form text field containing the planting date in ISO format" do
    assert_select "input#planting_planted_at[type='text'][value='2013-03-01']"
  end
end
