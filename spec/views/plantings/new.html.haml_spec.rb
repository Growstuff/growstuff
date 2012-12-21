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
        :id => 1,
        :user_id => @user.id,
        :name => 'Garden1'
      )
      @garden2 = Garden.create!(
        :id => 2,
        :user_id => @user.id,
        :name => 'Garden2'
      )

      @crop1 = Crop.create!(
        :id => 1,
        :system_name => 'Tomato',
        :en_wikipedia_url => 'http://blah'
      )
      @crop2 = Crop.create!(
        :id => 2,
        :system_name => 'Corn',
        :en_wikipedia_url => 'http://blah'
      )
      @crop3 = Crop.create!(
        :id => 3,
        :system_name => 'Chard',
        :en_wikipedia_url => 'http://blah'
      )

      # params to test default choice of crop and garden
      # XXX this is very wrong! but we are still trying to figure out
      # how to do it the right way. commiting as is, for now.
      render :template => 'plantings/new',
        :params => { :crop_id => 2, :garden_id => 2 }
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
        :html => /option value="2" selected="selected"/
    end

    it "selects a garden given in a param" do
      assert_select "select#planting_garden_id",
        :html => /option value="2" selected="selected"/
    end
  end
end
