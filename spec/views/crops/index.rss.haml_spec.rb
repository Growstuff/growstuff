# frozen_string_literal: true

require 'rails_helper'

describe 'crops/index.rss.haml' do
  before do
    controller.stub(:current_user) { nil }
    @author = create(:member)
    @tomato = create(:tomato)
    @maize = create(:maize)
    assign(:crops, [@tomato, @maize])
    render
  end

  it 'shows RSS feed title' do
    rendered.should have_content "Recently added crops"
  end

  it 'shows names of crops' do
    rendered.should have_content @tomato.name
    rendered.should have_content @maize.name
  end
end
