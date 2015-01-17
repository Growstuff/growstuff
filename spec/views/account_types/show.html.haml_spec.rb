require 'rails_helper'

describe "account_types/show" do
  before(:each) do
    @account_type = assign(:account_type, stub_model(AccountType,
      :name => "Name",
      :is_paid => false,
      :is_permanent_paid => false
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/false/)
    rendered.should match(/false/)
  end
end
