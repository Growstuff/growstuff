# frozen_string_literal: true

class ConversationsController < ApplicationController
  respond_to :html
  before_action :authenticate_member!
  before_action :set_box
  before_action :check_current_subject_in_conversation, only: %i(show update destroy)

  def index
    @conversations = if @box.eql? "inbox"
                       mailbox.inbox
                     elsif @box.eql? "sent"
                       mailbox.sentbox
                     else
                       mailbox.trash
                     end.paginate(page: params[:page])

    respond_with @conversations
  end

  def show
    @receipts = mailbox.receipts_for(@conversation)
    @receipts.mark_as_read
    @participants = @conversation.participants
  end

  def update
    @conversation.untrash(current_member)
    redirect_to conversations_path(box: params[:box])
  end

  def destroy
    @conversation = Mailboxer::Conversation.find(params[:id])
    @conversation.move_to_trash(current_member)
    redirect_to conversations_path(box: params[:box])
  end

  def destroy_multiple
    conversations = if @box.eql? 'sent'
                      mailbox.sentbox
                    else
                      mailbox.inbox
                    end
    conversations.where(id: params[:conversation_ids]).each do |conversation|
      conversation.move_to_trash(current_member)
    end
    redirect_to conversations_path(box: params[:box])
  end

  private

  def mailbox
    current_member.mailbox
  end

  def set_box
    @boxes = {
      'inbox' => { 'total' => mailbox.inbox.size, 'unread' => current_member.receipts.where(is_read: false).count },
      'sent'  => { 'total' => mailbox.sentbox.size, 'unread' => 0 },
      'trash' => { 'total' => mailbox.trash.size, 'unread' => 0 }
    }
    @box = if params[:box].blank? || !@boxes.keys.include?(params[:box])
             'inbox'
           else
             params[:box]
           end
  end

  def check_current_subject_in_conversation
    @conversation = Mailboxer::Conversation.find_by(id: params[:id])
    return unless @conversation.nil? || !@conversation.is_participant?(current_member)

    redirect_to conversations_path(box: box)
    nil
  end
end
