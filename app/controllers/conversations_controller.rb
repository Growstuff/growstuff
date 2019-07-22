class ConversationsController < ApplicationController
  respond_to :html
  before_action :authenticate_member!
  before_action :set_box

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

  private

  def mailbox
    current_member.mailbox
  end

  def set_box
    @boxes = {
      'inbox' => mailbox.inbox.size,
      'sent'  => mailbox.sentbox.size,
      'trash' => mailbox.trash.size
    }
    @box = if params[:box].blank? || !@boxes.keys.include?(params[:box])
             'inbox'
           else
             params[:box]
    end
  end
end
