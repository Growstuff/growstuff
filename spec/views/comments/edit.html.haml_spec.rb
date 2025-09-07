# frozen_string_literal: true

require 'rails_helper'

describe "comments/edit" do
  before do
    controller.stub(:current_user) { nil }
    assign(:comment, FactoryBot.create(:comment))
  end

  it "renders the edit comment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", action: comments_path(@comment), method: "post" do
      assert_select "textarea#comment_body", name: "comment[body]"
    end
  end
end
