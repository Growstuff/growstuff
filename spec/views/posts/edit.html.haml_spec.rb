require 'spec_helper'

describe "posts/edit" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @post = assign(:post, FactoryGirl.create(:post, :member => @member))
  end

  context "logged out" do
    it "doesn't show the post form if logged out" do
      render
      rendered.should contain "Only logged in members can do this"
    end
  end

  context "logged in" do
    before(:each) do
      sign_in @member
      render
    end

    it "renders the edit post form" do
      assert_select "form", :action => posts_path(@post), :method => "post" do
        assert_select "input#post_subject", :name => "post[subject]"
        assert_select "textarea#post_body", :name => "post[body]"
      end
    end
  end
end
