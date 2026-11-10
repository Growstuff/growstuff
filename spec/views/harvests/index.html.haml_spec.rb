# frozen_string_literal: true

require 'rails_helper'

describe "harvests/index.html.haml" do
  before do
    controller.stub(:current_user) { nil }
    @member = create(:member)
    @tomato = create(:tomato)
    @maize  = create(:maize)
    @pp = create(:plant_part)
    page = 1
    per_page = 2
    total_entries = 2
    harvests = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
                      create(:harvest,
                             crop:  @tomato,
                             owner: @member),
                      create(:harvest,
                             crop:       @maize,
                             plant_part: @pp,
                             owner:      @member)
                    ])
    end
    assign(:harvests, harvests)
    render
  end

  it "provides data links" do
    render
    expect(rendered).to have_content "The data on this page is available in the following formats:"
    assert_select "a", href: harvests_path(format: 'csv')
    assert_select "a", href: harvests_path(format: 'json')
  end

  it "displays member's name in title" do
    assign(:owner, @member)
    render
    expect(view.content_for(:title)).to have_content @member.login_name
  end

  it "displays crop's name in title" do
    assign(:crop, @tomato)
    render
    expect(view.content_for(:title)).to have_content @tomato.name
  end
end
