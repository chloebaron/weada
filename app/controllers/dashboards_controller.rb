class DashboardsController < ApplicationController
  def show
    @events = UserEvent.all


  end
end

