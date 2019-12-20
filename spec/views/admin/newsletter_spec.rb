# frozen_string_literal: true

require 'rails_helper'

describe 'admin/newsletter.html.haml', type: "view" do
  before do
    @member = FactoryBot.create(:admin_member)
    sign_in @member
    controller.stub(:current_user) { @member }
    @subscriber = FactoryBot.create(:newsletter_recipient_member)
    assign(:members, [@subscriber])
    render
  end

  it "lists newsletter subscribers by email" do
    expect(rendered).to have_content @subscriber.email
  end
end
