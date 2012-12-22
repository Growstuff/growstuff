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

      # create gardens and crops to populate dropdowns
      @garden1 = Garden.create!(
        :user_id => @user.id,
        :name => 'Garden1'
      )
      @garden2 = Garden.create!(
        :user_id => @user.id,
        :name => 'Garden2'
      )

      @crop1 = Crop.create!(
        :system_name => 'Tomato',
        :en_wikipedia_url => 'http://blah'
      )
      @crop2 = Crop.create!(
        :system_name => 'Corn',
        :en_wikipedia_url => 'http://blah'
      )
      @crop3 = Crop.create!(
        :system_name => 'Chard',
        :en_wikipedia_url => 'http://blah'
      )

      assign(:crop, @crop2)
      assign(:garden, @garden2)

      render
    end

    it "renders new planting form" do
      assert_select "form", :action => plantings_path, :method => "post" do
        assert_select "select#planting_garden_id", :name => "planting[garden_id]"
        assert_select "select#planting_crop_id", :name => "planting[crop_id]"
        assert_select "input#planting_quantity", :name => "planting[quantity]"
        assert_select "textarea#planting_description", :name => "planting[description]"
      end
    end

    it "selects a crop given in a param" do
      assert_select "select#planting_crop_id",
        :html => /option value="#{@crop2.id}" selected="selected"/
    end

    it "selects a garden given in a param" do
      assert_select "select#planting_garden_id",
        :html => /option value="#{@garden2.id}" selected="selected"/
    end
  end
end
