# frozen_string_literal: true

require 'rails_helper'

describe PlantingsController, '#show' do
  # A planting someone was given.
  let(:giver) { create(:member) }
  let(:original) { create(:planting, owner: giver, crop: create(:crop, name: 'sunflower')) }
  let(:receiver) { create(:member) }
  let(:received) { original.pass_on_to(receiver, receiver.gardens.first) }

  before { get planting_path(received) }

  it 'says who gave it' do
    expect(Capybara.string(response.body)).to have_link(giver.login_name, href: member_path(giver))
  end

  it 'links to the giver\'s planting' do
    expect(Capybara.string(response.body)).to have_link(href: planting_path(original))
  end
end
