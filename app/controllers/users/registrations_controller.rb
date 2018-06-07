# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  def collect_routine

  end


  # GET /resource/sign_up
  def new
    session[:user_sleep_schedule] = {
      "wake_up_hour"=>params[:wake_up_hour],
      "sleep_hour"=>params[:sleep_hour],
      "start_time"=>params[:start_time],
      "end_time"=>params[:end_time]
    }
    super
  end

  # protected

  # def after_sign_up_path_for(resource)
  #   raise
  #   user_google_oauth2_omniauth_authorize_path # Or :prefix_to_your_route
  #   redirect_to activities_path
  # end
  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  private

  def new_user_params
    params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation, :email, :sleep_hour, :wake_up_hour, :work_start_time, :work_end_time)
  end
end
