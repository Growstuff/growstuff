# frozen_string_literal: true

require 'rails_helper'

describe 'crops/index.rss.haml' do
  before do
    allow(controller).to receive(:current_user).and_return(nil)
    @author = create(:member)
    @tomato = create(:tomato)
    @maize = create(:maize)
    assign(:crops, [@tomato, @maize])
    render
  end

  it 'shows RSS feed title' do
    expect(rendered).to have_content "Recently added crops"
  end

  it 'shows names of crops' do
    expect(rendered).to have_content @tomato.name
    expect(rendered).to have_content @maize.name
  end
end
