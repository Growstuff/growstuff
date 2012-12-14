require 'spec_helper'

describe "crops/index" do
  before(:each) do
    assign(:crops, [
      stub_model(Crop,
        :system_name => "Maize",
        :en_wikipedia_url => "http://en.wikipedia.org/wiki/Maize"
      ),
      stub_model(Crop,
        :system_name => "Tomato",
        :en_wikipedia_url => "http://en.wikipedia.org/wiki/Tomato"
      )
    ])
  end

  it "renders a list of crops" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "a", :text => "Maize"
    assert_select "a", :text => "Tomato"
  end
  
  it "counts the number of crops" do
    render
    rendered.should contain "Displaying 2 crops"
  end
  
  context "logged out" do
    it "doesn't show the new crop link if logged out" do
      render
      rendered.should_not contain "New Crop"
    end
  end

  context "logged in" do

    before(:each) do
      @user = User.create(:email => "growstuff@example.com", :password => "irrelevant")
      @user.confirm!
      sign_in @user
      render
    end

    it "links to the add new form if logged in" do
      rendered.should contain "New Crop"
    end
  end
end
