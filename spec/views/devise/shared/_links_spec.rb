# frozen_string_literal: true

require 'rails_helper'

describe 'devise/shared/_links.haml', type: "view" do
  let(:controller_name) { 'anything but sessions' }
  let(:enabled) { [] }
  let(:mapping) do
    double("mappings", %i(registerable? recoverable? confirmable? lockable? omniauthable?).index_with { |option| enabled.include?(option) })
  end

  before do
    allow(view).to receive_messages(controller_name:, resource_name: "member", devise_mapping: mapping)
    render
  end

  context 'when not in sessions' do
    it { expect(rendered).to have_link 'Sign in' }
  end

  context 'when in sessions' do
    let(:controller_name) { 'sessions' }

    it { expect(rendered).to have_no_link 'Sign in' }
  end

  {
    registerable?: 'Join free',
    recoverable?:  'Forgot your password?',
    confirmable?:  "Didn't receive confirmation instructions?"
  }.each do |option, link|
    context "when #{option.to_s.chomp('?')}" do
      let(:enabled) { [option] }

      it { expect(rendered).to have_link link }
    end

    context "when not #{option.to_s.chomp('?')}" do
      it { expect(rendered).to have_no_link link }
    end
  end
end
