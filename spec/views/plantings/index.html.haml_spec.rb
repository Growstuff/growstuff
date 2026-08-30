# frozen_string_literal: true

require 'rails_helper'

describe "plantings/index.html.haml" do
  let(:member) { create(:member)                 }
  let(:garden) { create(:garden, owner: member)  }
  let(:tomato) { create(:tomato, name: 'tomato') }
  let(:maize)  { create(:maize, name: 'maize')   }

  before do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 3
    total_entries = 3
    plantings = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
                      create(:planting,
                             garden:,
                             crop:   tomato,
                             owner:  member),
                      create(:planting,
                             garden:,
                             crop:        maize,
                             owner:       garden.owner,
                             description: '',
                             planted_at:  Time.zone.local(2013, 1, 13)),
                      create(:planting,
                             garden:,
                             owner:       garden.owner,
                             crop:        tomato,
                             planted_at:  Time.zone.local(2013, 1, 13),
                             finished_at: Time.zone.local(2013, 1, 20),
                             finished:    true)
                    ])
    end
    assign(:plantings, plantings)
    render
  end

  describe "renders a list of plantings" do
    it { expect(rendered).to have_content tomato.name }
    it { expect(rendered).to have_content maize.name }
  end

  it "provides data links" do
    render
    expect(rendered).to have_content "The data on this page is available in the following formats:"
    assert_select "a", href: plantings_path(format: 'csv')
    assert_select "a", href: plantings_path(format: 'json')
    assert_select "a", href: plantings_path(format: 'rss')
  end

  it "displays member's name in title" do
    assign(:owner, member)
    render
    expect(view.content_for(:title)).to have_content member.login_name
  end

  it "displays crop's name in title" do
    assign(:crop, tomato)
    render
    expect(view.content_for(:title)).to have_content tomato.name
  end
end
