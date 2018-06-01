class ActivitiesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [:home]

  def index
    @activities = Activity.all
    @events = UserEvent.all.where(user: current_user, status: 0)
  end

  # def duration
  #   @events = UserEvent.all.where(user: current_user, status: 0)
  # end


end

