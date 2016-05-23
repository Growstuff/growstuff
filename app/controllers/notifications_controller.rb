class NotificationsController < ApplicationController
  include NotificationsHelper
  before_filter :authenticate_member!
  load_and_authorize_resource

  # GET /notifications
  def index
    @notifications = Notification.where(recipient_id: current_member).page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /notifications/1
  def show
    @notification = Notification.find(params[:id])
    @notification.read = true
    @notification.save
    @reply_link = reply_link(@notification)

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /notifications/new

  def new
    @notification = Notification.new
    @recipient = Member.find_by_id(params[:recipient_id])
    @subject   = params[:subject] || ""

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /notifications/1/reply
  def reply
    @notification = Notification.new
    @sender_notification = Notification.find(params[:id])
    @sender_notification.read = true
    @sender_notification.save
    @recipient = @sender_notification.sender
    @subject   = @sender_notification.subject =~ /^Re: / ?
      @sender_notification.subject :
      "Re: " + @sender_notification.subject
    

    respond_to do |format|
      format.html # reply.html.haml
    end
  end

  # DELETE /notifications/1
  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to notifications_url }
    end
  end

  # POST /notifications
  def create
    params[:notification][:sender_id] = current_member.id
    @notification = Notification.new(notification_params)
    @recipient = Member.find_by_id(params[:notification][:recipient_id])

    respond_to do |format|
      if @notification.save
        format.html { redirect_to notifications_path, notice: 'Message was successfully sent.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  private

  def notification_params
    params.require(:notification).permit(:sender_id, :recipient_id, :subject, :body, :post_id, :read)
  end
end
