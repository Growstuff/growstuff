class ConversationsController < ApplicationController
  before_action :authenticate_member!
  before_action :get_mailbox, :get_box # , :get_actor
  # before_action :check_current_subject_in_conversation, :only => [:show, :update, :destroy]

  def index
    @conversations = if @box.eql? "inbox"
                       @mailbox.inbox.paginate(page: params[:page])
                     elsif @box.eql? "sentbox"
                       @mailbox.sentbox.paginate(page: params[:page])
                     else
                       @mailbox.trash.paginate(page: params[:page])
                     end

    respond_to do |format|
      format.html { render @conversations if request.xhr? }
    end
  end

  def show
    @receipts = if @box.eql? 'trash'
                  @mailbox.receipts_for(@conversation).trash
                else
                  @mailbox.receipts_for(@conversation).not_trash
                end
    render action: :show
    @receipts.mark_as_read
  end

  def update
    @conversation.untrash(@actor) if params[:untrash].present?

    if params[:reply_all].present?
      last_receipt = @mailbox.receipts_for(@conversation).last
      @receipt = @actor.reply_to_all(last_receipt, params[:body])
    end

    @receipts = if @box.eql? 'trash'
                  @mailbox.receipts_for(@conversation).trash
                else
                  @mailbox.receipts_for(@conversation).not_trash
                end
    redirect_to action: :show
    @receipts.mark_as_read
  end

  def destroy
    @conversation.move_to_trash(@actor)

    respond_to do |format|
      format.html do
        if params[:location].present? && (params[:location] == 'conversation')
          redirect_to conversations_path(box: :trash)
        else
          redirect_to conversations_path(box: @box, page: params[:page])
        end
      end
      format.js do
        if params[:location].present? && (params[:location] == 'conversation')
          render js: "window.location = '#{conversations_path(box: @box, page: params[:page])}';"
        else
          render 'conversations/destroy'
        end
      end
    end
  end

  private

  def get_mailbox
    @mailbox = current_member.mailbox
  end

  def get_actor
    @actor = Actor.normalize(current_subject)
  end

  def get_box
    params[:box] = 'inbox' if params[:box].blank? || !%w(inbox sentbox trash).include?(params[:box])

    @box = params[:box]
  end

  def check_current_subject_in_conversation
    @conversation = Conversation.find_by(id: params[:id])

    if @conversation.nil? || !@conversation.is_participant?(@actor)
      redirect_to conversations_path(box: @box)
      return
    end
  end
end
