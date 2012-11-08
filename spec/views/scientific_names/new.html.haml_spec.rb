require 'spec_helper'

describe "scientific_names/new" do
  before(:each) do
    assign(:scientific_name, stub_model(ScientificName,
      :scientific_name => "MyString",
      :crop_id => 1
    ).as_new_record)
  end

  context "logged out" do
    it "doesn't show the SN form if logged out" do
      render
      rendered.should contain "Only logged in users can do this"
    end
  end

  context "logged in" do
    before(:each) do
      @user = User.create(:email => "growstuff@example.com", :password => "irrelevant")
      @user.confirm!
      sign_in @user
      render
    end

    it "renders new scientific_name form" do
      render
      # Run the generator again with the --webrat flag if you want to use webrat matchers
      assert_select "form", :action => scientific_names_path, :method => "post" do
        assert_select "input#scientific_name_scientific_name", :name => "scientific_name[scientific_name]"
        assert_select "input#scientific_name_crop_id", :name => "scientific_name[crop_id]"
      end
    end

  end

end
