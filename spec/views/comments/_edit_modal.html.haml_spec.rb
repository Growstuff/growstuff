# frozen_string_literal: true

require 'rails_helper'

describe 'comments/_edit_modal' do
  subject { rendered }

  let(:comment) { create(:comment) }

  before do
    render partial: 'comments/edit_modal', locals: { comment: }
  end

  it 'renders the localized modal title' do
    expect(rendered).to have_content(I18n.t('comments.edit_modal.title'))
  end

  it 'renders the localized comment label' do
    expect(rendered).to have_content(I18n.t('comments.edit_modal.your_comment'))
  end

  it 'renders the localized submit button' do
    expect(rendered).to have_button(I18n.t('comments.edit_modal.save'))
  end
end
