require 'spec_helper'

describe "plantings/edit" do
  before(:each) do
    @member = FactoryGirl.create(:member,
      :login_name => 'right',
      :email => 'right@example.com'
    )

    # creating two crops to make sure that the correct one is selected
    # in the form.
    @tomato = FactoryGirl.create(:tomato)
    @maize = FactoryGirl.create(:maize)

    # and likewise for gardens
    @garden =  FactoryGirl.create(:garden_z, :owner => @member)
    @garden2 = FactoryGirl.create(:garden_a, :owner => @member)

    @planting = assign(:planting,
      FactoryGirl.create(:planting, :garden => @garden, :crop => @tomato)
    )

  end

  context "logged in" do
    before(:each) do
      sign_in @member
      controller.stub(:current_user) { @member }
      render
    end

    it "renders the edit planting form" do
      assert_select "form", :action => plantings_path(@planting), :method => "post" do
        assert_select "input#planting_quantity", :name => "planting[quantity]"
        assert_select "textarea#planting_description", :name => "planting[description]"
        assert_select "select#planting_sunniness", :name => "planting[sunniness]"
        assert_select "select#planting_planted_from", :name => "planting[planted_from]"
      end
    end

    it 'includes helpful links for crops and gardens' do
      assert_select "a[href=#{new_garden_path}]", :text => "Add a garden."
      assert_select "a[href=#{Growstuff::Application.config.new_crops_request_link}]", :text => "Request new crops."
    end

    it "chooses the right crop" do
      assert_select "select#planting_crop_id",
        :html => /option value="#{@tomato.id}" selected="selected"/
    end

    it "chooses the right garden" do
      assert_select "select#planting_garden_id",
        :html => /option value="#{@garden.id}" selected="selected"/
    end

  end
end
