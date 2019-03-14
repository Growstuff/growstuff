# frozen_string_literal: true

require 'rails_helper'

describe "crops/new" do
  before do
    @crop = FactoryBot.create(:maize)
    3.times do
      @crop.scientific_names.build
    end
    assign(:crop, @crop)
    @member = FactoryBot.create(:crop_wrangling_member)
    sign_in @member
    controller.stub(:current_user) { @member }
    render
  end

  it "shows a link to crop wrangling guidelines" do
    assert_select "a[href^='http://wiki.growstuff.org']", "crop wrangling guide"
  end
end
