class ActivitiesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [:home]
  before_action :skip_footer, only: [:index]

  def index
    session.delete(:user_sleep_schedule)
    @activities = Activity.all
    @events = UserEvent.all.where(user: current_user, status: 0)
    @icons = {
      run: "heartbeat",
      park: "leaf",
      museum: "university",
      bbq: "fire",
      yoga: "align-center",
      cinema: "film",
      drinks: "beer",
      read: "book",
      gallery: "paint-brush",
      cafe: "coffee"
    }
  end

  # def duration
  #   @events = UserEvent.all.where(user: current_user, status: 0)
  # end



end

