require 'spec_helper'

describe "comments/new" do
  before(:each) do
    assign(:comment, FactoryGirl.create(:comment))
  end

  it "renders new comment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => comments_path, :method => "post" do
      assert_select "textarea#comment_body", :name => "comment[body]"
    end
  end
end
