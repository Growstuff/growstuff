require 'spec_helper'

describe "comments/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    assign(:comments, [
      FactoryGirl.create(:comment),
      FactoryGirl.create(:comment, :body => 'ROFL')
    ])
  end

  it "renders a list of comments" do
    render
    rendered.should contain 'OMG LOL'
    rendered.should contain 'ROFL'
  end
end
