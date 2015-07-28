require 'rails_helper'

feature "products" do
  context "admin user" do
    let(:member) { create :admin_member }
    let(:product) { create :product }
    
    background do
      login_as member
    end

    scenario "navigating to product admin" do
      visit admin_path
      click_link "Products"
      expect(current_path).to eq products_path
    end

    scenario "adding a product" do
      visit products_path
      click_link "New Product"
      expect(current_path).to eq new_product_path
      fill_in 'Name', with: 'Special offer'
      # note that failing to fill in a mandatory field has a messy error. This is not a priority defect but should be raised at some point.
      fill_in 'Minimum price', with: '150'
      click_button 'Save'
      expect(current_path).to eq product_path(Product.last)
      expect(page).to have_content 'Product was successfully created'
    end

    scenario 'editing product' do
      visit product_path product
      click_link 'Edit'
      fill_in 'Name', with: 'Something else'
      click_button 'Save'
      expect(current_path).to eq product_path(product)
      expect(page).to have_content 'Product was successfully updated'
      expect(page).to have_content 'Something else'
    end

    scenario 'deleting product'
    # this isn't possible. Should it be?
  end
end
