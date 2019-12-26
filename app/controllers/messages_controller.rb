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
    return if @recipient.nil?
  end

  def create
    if params[:conversation_id].present?
      @conversation = Mailboxer::Conversation.find(params[:conversation_id])
      current_member.reply_to_conversation(@conversation, params[:body])
      redirect_to conversation_path(@conversation)
    else
      recipient = Member.find(params[:recipient_id])
      body = params[:body]
      subject = params[:subject]
      @conversation = current_member.send_message(recipient, body, subject)
      redirect_to conversations_path(box: 'sentbox')
    end
  end
end
