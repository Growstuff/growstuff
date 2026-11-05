# frozen_string_literal: true

require 'rails_helper'

describe 'conversations/index' do
  let(:member) { create(:member) }
  let(:other_member) { create(:member) }
  let(:receipt) { other_member.send_message(member, 'Hello there!', 'Greetings') }
  let(:conversation) { receipt.conversation }
  let(:boxes) do
    {
      'inbox' => { 'total' => 1, 'unread' => 1 },
      'sent' => { 'total' => 0, 'unread' => 0 },
      'trash' => { 'total' => 0, 'unread' => 0 }
    }
  end

  before do
    allow(view).to receive(:current_member).and_return(member)
    assign(:boxes, boxes)
    assign(:box, 'inbox')
    page = 1
    per_page = 10
    total_entries = 1
    conversations = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([conversation])
    end
    assign(:conversations, conversations)
  end

  it 'renders the breadcrumb link for conversations' do
    render
    assert_select 'li.breadcrumb-item a', text: I18n.t('conversations.index.breadcrumb_conversations')
  end

  it 'renders the box tabs with localized labels' do
    render
    assert_select '.nav-link.inbox span', text: I18n.t('conversations.index.boxes.inbox')
    assert_select '.nav-link.sent span', text: I18n.t('conversations.index.boxes.sent')
    assert_select '.nav-link.trash span', text: I18n.t('conversations.index.boxes.trash')
  end

  it 'renders the page heading matching the active box' do
    render
    assert_select 'h1', text: I18n.t('conversations.index.boxes.inbox')
  end

  it 'renders the delete button with localized text' do
    render
    assert_select 'button[type="submit"]', text: /#{I18n.t('conversations.index.delete')}/
  end

  it 'renders deletion checkbox with localized aria-label' do
    render
    assert_select "input.selectable[aria-label='#{I18n.t('conversations.index.select_for_deletion')}']"
  end

  context 'when viewing the trash box' do
    before do
      assign(:box, 'trash')
    end

    it 'renders the restore action button with localized title' do
      render
      assert_select "a.restore[title='#{I18n.t('conversations.index.restore')}']"
    end
  end
end
