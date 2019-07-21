class ConversationsController < ApplicationController
  respond_to :html
  before_action :authenticate_member!
  before_action :check_current_subject_in_conversation, only: %i(show update destroy)

  def index
    @conversations = if box.eql? "inbox"
                       mailbox.inbox.paginate(page: params[:page])
                     elsif box.eql? "sentbox"
                       mailbox.sentbox.paginate(page: params[:page])
                     else
                       mailbox.trash.paginate(page: params[:page])
                     end

    respond_with @conversations
  end

  def show
    @receipts = mailbox.receipts_for(@conversation)
    @receipts.mark_as_read
  end

  def update
    @conversation.untrash(@actor) if params[:untrash].present?

    if params[:reply_all].present?
      last_receipt = mailbox.receipts_for(@conversation).last
      @receipt = @actor.reply_to_all(last_receipt, params[:body])
    end

    @receipts = if box.eql? 'trash'
                  mailbox.receipts_for(@conversation).trash
                else
                  mailbox.receipts_for(@conversation).not_trash
                end
    redirect_to action: :show
    @receipts.mark_as_read
  end

  def destroy
    @conversation = Mailboxer::Conversation.find params[:id]
    current_member.mark_as_deleted @conversation
    redirect_to conversations_path
  end

  private

  def mailbox
    current_member.mailbox
  end

  def box
    if params[:box].blank? || !%w(inbox sentbox trash).include?(params[:box])
      'inbox'
    else
      params[:box]
    end
  end

  def check_current_subject_in_conversation
    @conversation = Mailboxer::Conversation.find_by(id: params[:id])
    if @conversation.nil? || !@conversation.is_participant?(current_member)
      redirect_to conversations_path(box: box)
      return
    end
  end
end
