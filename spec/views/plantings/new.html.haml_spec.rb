require 'spec_helper'

describe "plantings/new" do
  before(:each) do
    assign(:planting, stub_model(Planting,
      :garden_id => 1,
      :crop_id => 1,
      :quantity => 1,
      :description => "MyText"
    ).as_new_record)
  end

  context "logged out" do
    it "doesn't show the planting form if logged out" do
      render
      rendered.should contain "Only logged in users can do this"
    end
  end

  context "logged in" do
    before(:each) do
      @user = User.create(:email => "growstuff@example.com",
                          :password => "irrelevant")
      @user.confirm!
      sign_in @user
      render
    end

    it "renders new planting form" do
      render

      # Run the generator again with the --webrat flag if you want to use webrat matchers
      assert_select "form", :action => plantings_path, :method => "post" do
        assert_select "select#planting_garden_id", :name => "planting[garden_id]"
        assert_select "select#planting_crop_id", :name => "planting[crop_id]"
        assert_select "input#planting_quantity", :name => "planting[quantity]"
        assert_select "textarea#planting_description", :name => "planting[description]"
      end
    end
  end
end
