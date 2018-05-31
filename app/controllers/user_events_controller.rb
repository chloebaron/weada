class UserEventsController < ApplicationController
  before_action :authenticate_user!, only: [:create]

  def new
    @user_event = UserEvent.new
  end

  def create
    params[:activity_ids].each do |activity_id|
      activity = Activity.find(activity_id)
      UserEvent.create(user: current_user, activity: activity, status: 0)
    end

    redirect_to dashboard_path
  end

  def edit

  end

  def update
  end

  def dashboard
    @events = UserEvent.all.where(user: current_user, status: 0)
  end

  # def destroy
  # end

  private

  def event_params
    params.permit(:activity_ids)
  end
end
