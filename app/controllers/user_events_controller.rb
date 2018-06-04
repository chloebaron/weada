class UserEventsController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  before_action :set_event, only: [:edit, :update]

  def new
    @user_event = UserEvent.new
  end

  def create
    # Destroy last pending user_events records
    UserEvent.where(status: 0).destroy_all
    params[:activity_ids].each do |activity_id|
      activity = Activity.find(activity_id)
      UserEvent.create(user: current_user, activity: activity, status: 0, duration: params[:user_events][:activity_id].to_i)
    end

    redirect_to dashboard_path
  end

  def edit
    # @eventevent.id?
  end

  def update
    @events = UserEvent.where(user: current_user, status: 0)

    @events.each do |event|
      event.update(duration: params[:user_events][event.id.to_s])
    end

    redirect_to dashboard_path
  end

  def duration
    @events = UserEvent.where(user: current_user, status: 0)
  end

  def dashboard
    @events = UserEvent.where(user: current_user, status: 0)
  end

  # def destroy
  # end

  private

  def event_params
    params.permit(:activity_ids)
  end

  def set_event
    @event = UserEvent.find_by(id: params[:id])
  end
end
