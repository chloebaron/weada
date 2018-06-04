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

    byebug

    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(auth)

    if @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in_and_redirect @user, event: :authentication
    else
      session['devise.google_data'] = request.env['omniauth.auth'].except(:extra) # Removing extra as it can overflow some session stores
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end
end
