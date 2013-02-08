require 'spec_helper'

describe "comments/new" do
  before(:each) do
    assign(:comment, stub_model(Comment,
      :post_id => 1,
      :author_id => 1,
      :body => "MyText"
    ).as_new_record)
  end

  it "renders new comment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => comments_path, :method => "post" do
      assert_select "textarea#comment_body", :name => "comment[body]"
    end
  end
end
