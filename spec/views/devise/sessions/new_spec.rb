# frozen_string_literal: true

require 'rails_helper'

describe 'devise/sessions/new.html.haml', type: "view" do
  context "logged in" do
    before do
      @view.stub(:resource).and_return(Member.new)
      @view.stub(:resource_name).and_return("member")
      @view.stub(:resource_class).and_return(Member)
      @view.stub(:devise_mapping).and_return(Devise.mappings[:member])
      render
    end

    it 'has some fields' do
      expect(rendered).to have_content 'Remember me'
      expect(rendered).to have_content 'Password'
    end
  end
end
