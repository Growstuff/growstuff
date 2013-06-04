require 'spec_helper'

describe "account_types/edit" do
  before(:each) do
    @account_type = assign(:account_type, stub_model(AccountType,
      :name => "MyString",
      :is_paid => false,
      :is_permanent_paid => false
    ))
  end

  it "renders the edit account_type form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => account_types_path(@account_type), :method => "post" do
      assert_select "input#account_type_name", :name => "account_type[name]"
      assert_select "input#account_type_is_paid", :name => "account_type[is_paid]"
      assert_select "input#account_type_is_permanent_paid", :name => "account_type[is_permanent_paid]"
    end
  end
end
