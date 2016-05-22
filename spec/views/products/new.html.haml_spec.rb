## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe "products/new" do
  before(:each) do
    assign(:product, stub_model(Product,
      name: "MyString",
      description: "MyString",
      min_price: "9.99"
    ).as_new_record)
  end

  it "renders new product form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", action: products_path, method: "post" do
      assert_select "input#product_name", name: "product[name]"
      assert_select "textarea#product_description", name: "product[description]"
      assert_select "input#product_min_price", name: "product[min_price]"
      assert_select "input#product_recommended_price", name: "product[recommended_price]"
      assert_select "select#product_account_type_id", name: "product[account_type_id]"
      assert_select "input#product_paid_months", name: "product[paid_months]"
    end
  end
end
