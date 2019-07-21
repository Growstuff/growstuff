class NotificationsController < ApplicationController
  include NotificationsHelper
  before_action :authenticate_member!
  load_and_authorize_resource
  respond_to :html

  # GET /notifications
  def index
    # @notifications = Notification.by_recipient(current_member).order(created_at: :desc).paginate(page: params[:page], per_page: 30)
  end

  # GET /notifications/1
  def show
    @notification.read = true
    @notification.save
    @reply_link = reply_link(@notification)
  end

  # GET /notifications/new

  def new
    @notification = Notification.new
    @recipient = Member.find_by(id: params[:recipient_id])
    @subject   = params[:subject] || ""
  end

  # GET /notifications/1/reply
  def reply
    @notification = Notification.new
    @sender_notification = Notification.find_by!(id: params[:notification_id], recipient: current_member)
    @sender_notification.read = true
    @sender_notification.save
    @recipient = @sender_notification.sender
    @subject   = if @sender_notification.subject.start_with? 'Re: '
                   @sender_notification.subject
                 else
                   "Re: #{@sender_notification.subject}"
                 end
  end

  # DELETE /notifications/1
  def destroy
    @notification.destroy
    redirect_to notifications_url
  end

  # POST /notifications
  def create
    # params[:notification][:sender_id] = current_member.id
    @notification = Notification.new(notification_params)
    @notification.sender = current_member
    @notification.recipient = Member.find_by(id: notification_params[:recipient_id])
    @body = notification_params[:body]
    @subject = notification_params[:subject]

    if @notification.save
      @notification.sender.send_message(@notification.recipient, @notification.body, @notification.subject)
      redirect_to notifications_path, notice: 'Message was successfully sent.'
    else
      render action: "new"
    end
  end

  private

  def notification_params
    params.require(:notification).permit(:sender_id, :recipient_id, :subject, :body, :post_id, :read)
  end
end
