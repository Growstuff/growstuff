# frozen_string_literal: true

require 'rails_helper'

describe "members/index" do
  let(:member) { create(:london_member) }

  before do
    controller.stub(:current_user) { nil }
    page = 1
    per_page = 2
    total_entries = 2
    members = [member, member]
    assign(:pagy, Pagy::Offset.new(count: total_entries, limit: per_page, page:))
    assign(:members, members)
    render
  end

  it "contains two gravatar icons" do
    assert_select "img", src: %r{gravatar\.com/avatar}, count: 2
  end

  it 'contains member locations' do
    expect(rendered).to have_content member.location
  end
end
