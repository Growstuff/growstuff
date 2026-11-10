# frozen_string_literal: true

require 'rails_helper'

describe "messages/new" do
  subject { render }

  let(:recipient) { create(:member) }

  before do
    controller.stub(:current_user) { create(:member) }
    assign(:recipient, recipient)
    render
  end

  describe "renders localized title and breadcrumbs" do
    it 'renders localized page title' do
      expect(view.content_for(:title)).to eq(
        I18n.t('messages.new.title', recipient:)
      )
    end

    it 'renders localized breadcrumb link to conversations' do
      expect(view.content_for(:breadcrumbs)).to have_link(
        I18n.t('messages.new.breadcrumb_messages'),
        href: conversations_path
      )
    end
  end
end
