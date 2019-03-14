# frozen_string_literal: true

require 'rails_helper'

describe "crops/hierarchy" do
  before do
    controller.stub(:current_user) { nil }
    @tomato = FactoryBot.create(:tomato)
    @roma = FactoryBot.create(:crop, name: 'Roma tomato', parent: @tomato)
    assign(:crops, [@tomato, @roma])
    render
  end

  it "shows crop hierarchy" do
    assert_select "ul>li>ul>li", text: @roma.name
  end
end
