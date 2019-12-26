# frozen_string_literal: true

require 'rails_helper'

describe 'home/_members.html.haml', type: "view" do
  before do
    @member = FactoryBot.create(:london_member)
    @member.updated_at = 2.days.ago
    assign(:members, [@member])

    @planting = FactoryBot.create(:planting, owner: @member)
    render
  end

  it 'Has a heading' do
    expect(rendered).to have_content "Some of our members"
  end

  describe 'Shows members' do
    it { expect(rendered).to have_content @member.login_name }
    it { expect(rendered).to have_content @member.location }
  end
end
