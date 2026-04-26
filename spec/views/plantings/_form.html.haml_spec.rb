# frozen_string_literal: true

require 'rails_helper'

describe "plantings/_form" do
  before do
    @member = create(:member)
    @garden = create(:garden, owner: @member)
    @uppercase = create(:uppercasecrop)
    @lowercase = create(:lowercasecrop)
    @crop = @lowercase # needed to render the form

    @planting = create(:planting,
                       garden:     @garden,
                       crop:       @crop,
                       owner:      @member,
                       planted_at: Date.new(2013, 3, 1))

    @gardens = @member.gardens
    sign_in @member
    render
  end

  it "has a free-form text field containing the planting date in ISO format" do
    assert_select "input#planting_planted_at[type='text'][value='2013-03-01']"
  end
end
