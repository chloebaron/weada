class UserEventsController < ApplicationController
  def new
    @user_event = UserEvent.new
  end

  def create
  end

  private

  def user_event_params
    params.require(:user_event).permit(:duration, :activity_id)
  end


end
