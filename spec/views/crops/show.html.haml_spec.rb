require 'spec_helper'

describe "crops/show" do
  before(:each) do
    @crop = assign(:crop, stub_model(Crop,
      :system_name => "System Name",
      :en_wikipedia_url => "En Wikipedia Url"
    ))
  end

  context "logged out" do
    it "doesn't show the edit links if logged out" do
      render
      rendered.should_not contain "Edit"
    end
  end

  context "logged in" do

    before(:each) do
      @user = User.create(:email => "growstuff@example.com", :password => "irrelevant")
      @user.confirm!
      sign_in @user
      render
    end

    it "links to the edit crop form" do
      render
      rendered.should contain "Edit"
    end
  end

end
