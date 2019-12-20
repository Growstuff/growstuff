# frozen_string_literal: true

require 'rails_helper'

describe 'harvests/index.rss.haml' do
  before do
    controller.stub(:current_user) { nil }
    @member = FactoryBot.create(:member)
    @tomato = FactoryBot.create(:tomato)
    @maize  = FactoryBot.create(:maize)
    @pp = FactoryBot.create(:plant_part)
    page = 1
    per_page = 2
    total_entries = 2
    harvests = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
                      FactoryBot.create(:harvest,
                                        crop: @tomato,
                                        owner: @member),
                      FactoryBot.create(:harvest,
                                        crop: @maize,
                                        plant_part: @pp,
                                        owner: @member,
                                        quantity: 2)
                    ])
    end
    assign(:harvests, harvests)
    render
  end

  it 'shows RSS feed title' do
    rendered.should have_content "Recent harvests from all members"
  end

  it "displays crop's name in title" do
    assign(:crop, @tomato)
    render
    expect(rendered).to have_content @tomato.name
  end

  it 'shows formatted content of harvest posts' do
    expect(rendered).to have_content "<p>Quantity: "
  end
end
