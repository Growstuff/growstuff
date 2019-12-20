# frozen_string_literal: true

require 'rails_helper'

describe 'devise/registrations/new.html.haml', type: "view" do
  context "logged in" do
    before do
      @view.stub(:resource).and_return(Member.new)
      @view.stub(:resource_name).and_return("member")
      @view.stub(:resource_class).and_return(Member)
      @view.stub(:devise_mapping).and_return(Devise.mappings[:member])
      render
    end

    it 'has some fields' do
      rendered.should have_content 'Email'
    end

    it 'has a checkbox for newsletter subscription' do
      assert_select "input[id=member_newsletter][type=checkbox]"
    end
  end
end
