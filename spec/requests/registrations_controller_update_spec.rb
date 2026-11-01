# frozen_string_literal: true

require 'rails_helper'

describe RegistrationsController, '#update' do
  let(:member) { create(:member, bio: 'Hello') }

  before do
    sign_in member
    put member_registration_path, params: { member: { bio: 'Hello again', location: 'somewhere over the rainbow' } }
  end

  it 'saves the rest of the profile' do
    expect(member.reload.bio).to eq('Hello again')
  end

  it 'does not take a location typed in' do
    expect(member.reload.location).to be_blank
  end
end
