require 'spec_helper'

describe "comments/new" do
  before(:each) do
    controller.stub(:current_user) { nil }
    assign(:comment, FactoryGirl.create(:comment))
  end

  it "renders new comment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => comments_path, :method => "post" do
      assert_select "textarea#comment_body", :name => "comment[body]"
    end
  end

  it 'shows markdown help' do
    render
    rendered.should contain 'Markdown'
  end

end
