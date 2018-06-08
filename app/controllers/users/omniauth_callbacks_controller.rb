class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    auth = request.env['omniauth.auth']

    # drive = Google::Apis::DriveV2::DriveService.new
    # drive.authorization.access_token = auth.credentials.token
    # drive.authorization.refresh_token = auth.credentials.refresh_token
    # drive.authorization.client_id = ENV['GOOGLE_CLIENT_ID']
    # drive.authorization.client_secret = ENV['GOOGLE_CLIENT_SECRET']
    # drive.authorization.refresh!

    # drive = Google::Apis::DriveV2::DriveService.new

    # drive = Google::Apis::DriveV2::DriveService.new

    # @client = Google::APIClient.new
    # @service = @client.discovered_api('calendar', 'v3')

    # byebug

    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(auth, session[:user_sleep_schedule])

    if @user.nil?
      flash[:alert] = "You must create an account before you sign in"
      redirect_to users_registrations_collect_routine_url
    elsif @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in @user, event: :authentication
      # raise
      if current_user.user_events.empty?
        redirect_to activities_url
      else
        redirect_to dashboard_url
      end
    else
      session['devise.google_data'] = request.env['omniauth.auth'].except(:extra) # Removing extra as it can overflow some session stores
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
    # raise
  end
end

