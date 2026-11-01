# frozen_string_literal: true

require 'rails_helper'

describe GardensController, 'garden stall card', flipper: :garden_stall do
  let(:owner) { create(:member) }
  let(:nursery) { create(:garden, owner:, nursery: true) }

  context 'when the owner looks at their nursery' do
    before do
      sign_in owner
      get garden_path(nursery)
    end

    it 'offers to open a stall' do
      expect(Capybara.string(response.body)).to have_link('Open a garden stall', href: member_stall_path(owner))
    end
  end

  context 'when a visitor looks at the nursery' do
    before { get garden_path(nursery) }

    it 'has no stall card' do
      expect(Capybara.string(response.body)).to have_no_css('.stall-card')
    end
  end
end
