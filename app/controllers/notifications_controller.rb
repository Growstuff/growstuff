class NotificationsController < ApplicationController
  load_and_authorize_resource
  # GET /notifications
  def index
    @notifications = Notification.find_all_by_recipient_id(current_member)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /notifications/1
  def show
    @notification = Notification.find(params[:id])
    @notification.read = true
    @notification.save

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /notifications/new

  def new
    @notification = Notification.new
    @recipient = Member.find_by_id(params[:recipient_id])

    respond_to do |format|
      format.html # new.html.erb
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
    @notification = Notification.new(params[:notification])
    @recipient = Member.find_by_id(params[:notification][:recipient_id])

    respond_to do |format|
      if @notification.save
        format.html { redirect_to @recipient, notice: 'Message was successfully sent.' }
      else
        format.html { render action: "new" }
      end
    end
  end
end
