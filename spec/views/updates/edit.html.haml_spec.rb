require 'spec_helper'

describe "updates/edit" do
  before(:each) do
    @update = assign(:update, stub_model(Update,
      :user_id => 1,
      :subject => "MyString",
      :body => "MyText"
    ))
  end

  it "renders the edit update form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => updates_path(@update), :method => "post" do
      assert_select "input#update_user_id", :name => "update[user_id]"
      assert_select "input#update_subject", :name => "update[subject]"
      assert_select "textarea#update_body", :name => "update[body]"
    end
  end
end
