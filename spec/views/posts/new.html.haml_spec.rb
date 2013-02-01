require 'spec_helper'

describe "posts/new" do
  before(:each) do
    @author = FactoryGirl.create(:member)
    assign(:post, FactoryGirl.create(:post, :author => @author))
    sign_in @author
    controller.stub(:current_user) { @author }
    render
  end

  it "renders new post form" do
    assert_select "form", :action => posts_path, :method => "post" do
      assert_select "input#post_subject", :name => "post[subject]"
      assert_select "textarea#post_body", :name => "post[body]"
    end
  end
end
