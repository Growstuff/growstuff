# frozen_string_literal: true

require 'rails_helper'

describe "jobs/_card" do
  let(:owner) { create(:member) }
  let(:garden) { create(:garden, owner:) }
  let(:planting) { create(:planting, owner:, garden:) }
  let(:job) { create(:job, owner:, garden:, planting:) }

  before do
    allow(view).to receive_messages(member_signed_in?: false, current_member: nil)
  end

  it "renders garden and planting links inside ul.list-unstyled" do
    render partial: 'jobs/card', locals: { job: }

    expect(rendered).to have_css('ul.list-unstyled > li', count: 2)
    expect(rendered).not_to have_css('p > ul.list-unstyled')
    expect(rendered).not_to have_css('.card-body > p > li')
  end
end
