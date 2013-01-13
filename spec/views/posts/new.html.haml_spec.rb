require 'spec_helper'

describe "posts/new" do
  before(:each) do
    @author = FactoryGirl.create(:member)
    assign(:post, FactoryGirl.create(:post, :author => @author))
  end

  context "logged out" do
    it "doesn't show the post form if logged out" do
      render
      rendered.should contain "Only logged in members can do this"
    end
  end

  context "logged in" do
    before(:each) do
      sign_in @author
      render
    end

    it "renders new post form" do
      assert_select "form", :action => posts_path, :method => "post" do
        assert_select "input#post_subject", :name => "post[subject]"
        assert_select "textarea#post_body", :name => "post[body]"
      end
    end
  end
end
