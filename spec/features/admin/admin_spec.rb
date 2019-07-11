require 'rails_helper'

describe "forums", js: true do
  context "as an admin user" do
    let(:member) { create :admin_member }

    before do
      login_as member
    end

    it "navigating to forum admin with js" do
      visit admin_path
      Percy.snapshot(page, name: 'Admin page')
    end
  end
end
