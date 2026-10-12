# frozen_string_literal: true

require 'rails_helper'

describe 'home/_blurb.html.haml', type: "view" do
  context 'signed out' do
    before do
      controller.stub(:current_user) { nil }
      render
    end

    it 'has description' do
      expect(rendered).to have_content 'is a community of food gardeners'
    end

    it 'has a link to join' do
      expect(rendered).to have_link 'Join free', href: new_member_registration_path
    end

    it 'has a link to sign in' do
      expect(rendered).to have_link 'Sign in', href: new_member_session_path
    end

    it 'says the data is public' do
      expect(rendered).to have_content 'Everything you record is public open data'
    end
  end
end
