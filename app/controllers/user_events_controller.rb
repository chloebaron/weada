class UserEventsController < ApplicationController
  def new
    @user_event = UserEvent.new
    authorize @user_event
  end

  def create
    user_event_params[:activity_id].reject!(&:blank?).each do |activity|
      @user_event = UserEvent.new(activity_id: activity, duration: )
    end
    authorize @user_event
  end

  private

  def user_event_params
    params.require(:user_event).permit(:duration, :activity_id)
  end
end
