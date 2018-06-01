class PagesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [:home]

  def home
  end

  def user_time_info
    new_user = User.new

    redirect_to calendars_path
  end
end
