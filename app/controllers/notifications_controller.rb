class NotificationsController < ApplicationController
  load_and_authorize_resource
  # GET /notifications
  # GET /notifications.json
  def index
    @notifications = Notification.find_all_by_recipient_id(current_member)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @notifications }
    end
  end

  # GET /notifications/1
  # GET /notifications/1.json
  def show
    @notification = Notification.find(params[:id])
    @notification.read = true
    @notification.save

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @notification }
    end
  end

  # DELETE /notifications/1
  # DELETE /notifications/1.json
  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to notifications_url }
      format.json { head :no_content }
    end
  end
end
