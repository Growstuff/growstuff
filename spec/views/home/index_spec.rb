# frozen_string_literal: true

require 'rails_helper'

describe 'home/index.html.haml', type: "view" do
  context 'logged out' do
    before do
      controller.stub(:current_user) { nil }
      render
    end

    it 'shows the hero' do
      expect(rendered).to have_content 'Know what to grow'
    end

    it 'shows the recently planted strip' do
      expect(rendered).to have_content 'Planted this week'
    end

    it 'links to the story of the project' do
      expect(rendered).to have_link 'Our story', href: about_path
    end

    it 'explains why to sign in' do
      expect(rendered).to have_content 'Why sign in'
    end
  end
end
