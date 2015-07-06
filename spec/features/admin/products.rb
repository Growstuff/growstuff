require 'rails_helper'

feature "products" do
  context "admin user" do
    let(:member) { FactoryGirl.create(:admin_member) }
    
    background do
      login_as member
    end

    scenario "navigating to product admin" do
      visit admin_path
      click_link "Products"
      current_path.should eq products_path
    end

    scenario "adding a product" do
      visit products_path
      click_link "New Product"
      current_path.should eq new_product_path
      fill_in 'Name', :with => 'Special offer'
      # note that failing to fill in a mandatory field has a messy error. This is not a priority defect but should be raised at some point.
      fill_in 'Minimum price', :with => '150'
      click_button 'Save'
      current_path.should eq product_path(Product.last)
      page.should have_content 'Product was successfully created'
    end

    scenario 'editing product' do
      p = FactoryGirl.create(:product)
      visit product_path(p)
      click_link 'Edit'
      fill_in 'Name', :with => 'Something else'
      click_button 'Save'
      current_path.should eq product_path(p)
      page.should have_content 'Product was successfully updated'
      page.should have_content 'Something else'
    end

    scenario 'deleting product'
    # this isn't possible. Should it be?
  end
end
