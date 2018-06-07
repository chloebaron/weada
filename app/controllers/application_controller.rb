class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
    # For additional fields in app/views/devise/registrations/new.html.erb
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: [:first_name, :last_name, :wake_up_hour, :sleep_hour, :work_start_time, :work_end_time]
      )


    # For additional in app/views/devise/registrations/edit.html.erb
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end



  def skip_footer
    @skip_footer = true
  end

  def default_url_options
  { host: ENV["HOST"] || "localhost:3000" }
  end

protected

  def after_sign_in_path_for(resource)
    request.env['omniauth.origin'] || stored_location_for(resource) || activities_path
  end
end
