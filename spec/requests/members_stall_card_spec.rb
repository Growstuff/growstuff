# frozen_string_literal: true

require 'rails_helper'

describe MembersController, '#show', flipper: :garden_stall do
  let(:owner) { create(:member) }

  context 'when members look at their own profile' do
    before do
      sign_in owner
      get member_path(owner)
    end

    it 'offers to open a stall' do
      expect(Capybara.string(response.body)).to have_link('Open a garden stall', href: member_stall_path(owner))
    end
  end

  context 'when someone else looks at the profile' do
    before do
      sign_in create(:member)
      get member_path(owner)
    end

    it 'has no stall card' do
      expect(Capybara.string(response.body)).to have_no_css('.stall-card')
    end
  end
end
