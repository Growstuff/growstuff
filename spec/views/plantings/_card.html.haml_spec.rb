# frozen_string_literal: true

require 'rails_helper'

describe "plantings/_card" do
  let(:owner) { create(:member) }
  let(:planting) { create(:planting, owner:, garden: create(:garden, owner:)) }

  # The test environment has caching off, so turn it on here: without it these
  # examples pass whatever the cache key is, and prove nothing.
  around do |example|
    store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = store
  end

  before { controller.perform_caching = true }

  def render_card_as(member)
    # can? reads through the controller's current_user, as elsewhere here.
    allow(controller).to receive(:current_user) { member }
    allow(view).to receive_messages(member_signed_in?: member.present?, current_member: member)
    # `rendered` accumulates across renders within an example, so take what
    # this render itself returned.
    render partial: 'plantings/card', locals: { planting: }
  end

  # The fragment is cached, so its key has to carry whether the viewer owns the
  # planting. Keyed on the planting alone, whoever renders first decides what
  # everyone after them sees.
  it "shows the owner their own quick actions" do
    expect(render_card_as(owner)).to have_css '.planting-quick-actions'
  end

  it "does not show them to somebody else, even once the owner has primed the cache" do
    render_card_as(owner)
    expect(render_card_as(create(:member))).to have_no_css '.planting-quick-actions'
  end

  it "shows them to the owner even once a visitor has primed the cache" do
    render_card_as(create(:member))
    expect(render_card_as(owner)).to have_css '.planting-quick-actions'
  end
end
