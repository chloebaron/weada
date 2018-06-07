class ActivitiesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [:home]
  before_action :skip_footer, only: [:index]
  protect_from_forgery



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

  protected
    def after_sign_in_path_for(resource)
      sign_in_url = new_user_session_url
      if request.referer == sign_in_url
        super
      else
        stored_location_for(resource) || request.referer || activities_path
      end
    end



end

