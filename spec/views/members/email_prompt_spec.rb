# frozen_string_literal: true

require 'rails_helper'

describe 'members/_email_prompt' do
  let(:member) { build_stubbed(:member, email: nil) }

  before { render partial: 'members/email_prompt', locals: { member: } }

  it 'tells them they have no email' do
    expect(rendered).to include("You haven't set an email address")
  end

  it 'says it will be confirmed first' do
    expect(rendered).to include('send you a link to confirm it first')
  end
end
