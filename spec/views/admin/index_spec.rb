# frozen_string_literal: true

require 'rails_helper'

describe 'admin/index.html.haml', type: "view" do
  before do
    @member = FactoryBot.create(:admin_member)
    sign_in @member
    controller.stub(:current_user) { @member }
    render
  end

  it "includes links to manage various things" do
    assert_select "a", href: admin_roles_path
    assert_select "a", href: forums_path
  end

  it "has a link to newsletter subscribers" do
    expect(rendered).to have_content "Newsletter subscribers"
  end
end
