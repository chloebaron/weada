class UserEventsController < ApplicationController
  def new
    @user_event = UserEvent.new
    authorize @user_event
  end

  def create
    @user_event = UserEvent.new()
  end

  private

  def user_event_params
    params.require(:user_event).permit(:duration, :activity_id)
  end
end
