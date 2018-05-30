class UserEventsController < ApplicationController
  def new
    @user_event = UserEvent.new
    authorize @user_event
  end

  def create
    data = [ {duration: 30, activity_id: 1 }, { duration: 60, activity_id: 2}, { duration: 30, activity_id: 3 } ]
  end

  def determine

  end

  private

  def user_event_params
    params.require(:user_event).permit(:duration, :activity_id)
  end

  # def sunny?(precip_probability)
  #   precipProbability >= 0.3
  # end

  # def windy?(wind_speed)
  #   wind_speed >= 15.0
  # end

  # def apparent_temp_nice?(apparent_temperature)
  #   apparent_temperature >= 23.0
  # end

  # def cloudy?(cloud_cover)
  #   cloud_cover >= 0.5
  # end

end
