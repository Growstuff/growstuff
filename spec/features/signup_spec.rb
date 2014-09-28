require 'spec_helper'

feature "signup" do

  scenario "signup" do
    visit root_path
    first('.signup a').click

    expect(current_path).to eq(new_member_registration_path)
  end


end
