class UserEventsController < ApplicationController
  # skip_before_action :authenticate_user!, only: [:index]

  def new
    @user_event = UserEvent.new
  end

  def create
    @user_event = UserEvent.new(event_params)
    if @user_event.save
      redirect_to root_path
    else
      render :new
    end
  end

  # def edit
  # end

  # def update
  # end

  # def destroy
  # end

  private

  def event_params
    params.require(:user_event).permit(:name, :duration)
  end
end
