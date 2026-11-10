# frozen_string_literal: true

class MessagesController < ApplicationController
  respond_to :html, :json
  before_action :authenticate_member!
  def index
    redirect_to conversations_path(box: @box)
  end

  def show
    if (@message = Message.find_by(id: params[:id])) && (@conversation = @message.conversation)
      if @conversation.is_participant?(current_member)
        redirect_to conversation_path(@conversation, box: @box, anchor: "message_" + @message.id.to_s)
        return
      end
    end
    redirect_to conversations_path(box: @box)
  end

  def new
    return if params[:recipient_id].blank?

    @recipient = Member.find_by(id: params[:recipient_id])
    @subject = params[:subject]
    # A message asking about seeds is attached to them, so the reply can find them.
    @seed = Seed.find_by(id: params[:seed_id], owner_id: @recipient&.id)
    nil if @recipient.nil?
  end

  def create
    if params[:conversation_id].present?
      @conversation = Mailboxer::Conversation.find(params[:conversation_id])
      return head :forbidden unless @conversation.is_participant?(current_member)

      # Check if any of the recipients have blocked the sender
      if @conversation.recipients.any? { |recipient| recipient.already_blocking?(current_member) }
        flash[:error] = "You cannot reply to this conversation because one of the recipients has blocked you."
        redirect_to conversation_path(@conversation)
        return
      end
      receipt = current_member.reply_to_conversation(@conversation, params[:body])
      return render_delivery_errors(receipt) unless receipt.persisted?

      redirect_to conversation_path(@conversation)
    else
      recipient = Member.find(params[:recipient_id])
      @recipient = recipient
      @subject = params[:subject]
      @seed = Seed.find_by(id: params[:seed_id], owner_id: recipient.id)
      if recipient.already_blocking?(current_member)
        flash[:error] = "You cannot send a message to a member who has blocked you."
        redirect_back_or_to(root_path)
        return
      end
      body = params[:body]
      subject = params[:subject]
      receipt = current_member.send_message(recipient, body, subject)
      return render_delivery_errors(receipt) unless receipt.persisted?

      receipt.notification.update(notified_object: @seed) if @seed
      redirect_to conversations_path(box: 'sent')
    end
  end

  private

  def render_delivery_errors(receipt)
    @body = params[:body]
    flash.now[:error] = receipt.notification.errors.full_messages.to_sentence
    render :new, status: :unprocessable_content
  end
end
