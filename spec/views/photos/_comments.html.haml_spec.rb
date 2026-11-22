# frozen_string_literal: true

require 'rails_helper'

describe 'photos/_comments' do
  let(:owner) { create(:member) }
  let(:photo) { create(:photo, owner: owner) }
  let(:reader) { create(:member) }

  before { create(:comment, commentable: photo, author: owner, body: 'Thanks!') }

  # The view asks for the member itself, and the ability asks the controller for the user.
  def sign_in_as(member)
    controller.stub(:current_user) { member }
    allow(view).to receive_messages(member_signed_in?: member.present?, current_member: member)
  end

  context 'when signed in' do
    before do
      sign_in_as(reader)
      render partial: 'photos/comments', locals: { photo: photo }
    end

    it 'shows the comment' do
      assert_select '.photo-comment-body', text: /Thanks!/
    end

    it 'marks the photographer' do
      assert_select '.photo-comment-badge-photographer'
    end

    it 'has a box to add a comment' do
      assert_select "form.photo-comment-form[action='#{comments_path}'] textarea"
    end

    it 'has no invitation to sign in' do
      assert_select '.photo-comment-signin', false
    end
  end

  context 'when signed in as the commenter' do
    before do
      sign_in_as(owner)
      render partial: 'photos/comments', locals: { photo: photo }
    end

    it 'marks their own comment' do
      assert_select '.photo-comment-badge-you'
    end

    it 'lets them delete it' do
      assert_select ".photo-comment-actions a[data-method='delete']"
    end
  end

  context 'when signed out' do
    before do
      sign_in_as(nil)
      render partial: 'photos/comments', locals: { photo: photo }
    end

    it 'invites them to sign in' do
      assert_select ".photo-comment-signin a[href='#{new_member_session_path}']"
    end

    it 'has no box to add a comment' do
      assert_select 'form.photo-comment-form', false
    end
  end

  context 'when signed in and there are no comments' do
    let(:photo) { create(:photo) }

    before do
      photo.comments.destroy_all
      sign_in_as(reader)
      render partial: 'photos/comments', locals: { photo: photo }
    end

    it 'says there are none yet' do
      assert_select '.photo-comment-empty'
    end
  end
end
