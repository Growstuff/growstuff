require 'spec_helper'

describe "updates/edit" do
  before(:each) do
    @user = FactoryGirl.create(:user)
    @update = assign(:update, FactoryGirl.create(:update, :user => @user))
  end

  context "logged out" do
    it "doesn't show the update form if logged out" do
      render
      rendered.should contain "Only logged in users can do this"
    end
  end

  context "logged in" do
    before(:each) do
      sign_in @user
      render
    end

    it "renders the edit update form" do
      assert_select "form", :action => updates_path(@update), :method => "post" do
        assert_select "input#update_subject", :name => "update[subject]"
        assert_select "textarea#update_body", :name => "update[body]"
      end
    end
  end
end
