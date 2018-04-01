require 'rails_helper'

describe "plantings/_form" do
  before(:each) do
    @member = FactoryBot.create(:member)
    @garden = FactoryBot.create(:garden, owner: @member)
    @uppercase = FactoryBot.create(:uppercasecrop)
    @lowercase = FactoryBot.create(:lowercasecrop)
    @crop = @lowercase # needed to render the form

    @planting = FactoryBot.create(:planting,
      garden: @garden,
      crop: @crop,
      owner: @member,
      planted_at: Date.new(2013, 3, 1))

    sign_in @member
    render
  end

  it "has a free-form text field containing the planting date in ISO format" do
    assert_select "input#planting_planted_at[type='text'][value='2013-03-01']"
  end
end
