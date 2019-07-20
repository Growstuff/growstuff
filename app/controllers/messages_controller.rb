class MessagesController < ApplicationController
  before_action :authenticate_member!
  before_action :get_mailbox #, :get_box, :get_actor
  def index
    redirect_to conversations_path(box: @box)
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    if (@message = Message.find_by(id: params[:id])) && (@conversation = @message.conversation)
      if @conversation.is_participant?(@actor)
        redirect_to conversation_path(@conversation, box: @box, anchor: "message_" + @message.id.to_s)
        return
      end
    end
    redirect_to conversations_path(box: @box)
  end

  def new
    @message = Mailboxer::Message.new
    if params[:recipient_id].present?
      @recipient = Member.find_by(id: params[:recipient_id])
      return if @recipient.nil?

      # @recipient = nil if Member.normalize(@recipient) == Actor.normalize(current_subject)
    end
  end

  # GET /messages/1/edit
  def edit; end

  # POST /messages
  # POST /messages.xml
  def create
    @recipients =
      if params[:_recipients].present?
        @recipients = params[:_recipients].split(',').map { |r| Actor.find(r) }
      else
        []
      end

    @receipt = @actor.send_message(@recipients, params[:body], params[:subject])
    if @receipt.errors.blank?
      @conversation = @receipt.conversation
      flash[:success] = t('mailboxer.sent')
      redirect_to conversation_path(@conversation, box: :sentbox)
    else
      render action: :new
    end
  end

  # PUT /messages/1
  # PUT /messages/1.xml
  def update; end

  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy; end

  private

  def get_mailbox
    @mailbox = current_subject.mailbox
  end

  def get_actor
    @actor = Actor.normalize(current_subject)
  end

  def get_box
    if params[:box].blank? || !%w(inbox sentbox trash).include?(params[:box])
      @box = "inbox"
      return
    end
    @box = params[:box]
  end

  def current_subject
    @current_subject ||=
      # current_subject_from_params  ||
      # current_subject_from_session ||
        current_member
  end
end
