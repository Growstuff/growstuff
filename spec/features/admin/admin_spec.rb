# frozen_string_literal: true

require 'rails_helper'

describe "forums", js: true do
  context 'signed in admin' do
    include_context 'signed in admin'
    it "navigating to forum admin with js" do
      visit admin_path
      Percy.snapshot(page, name: 'Admin page')
    end
  end
end
