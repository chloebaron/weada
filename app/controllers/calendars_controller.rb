class CalendarsController < ApplicationController

  def show
    client = Signet::OAuth2::Client.new(client_options)
    redirect_to client.authorization_uri.to_s
  end

  def callback
    client = Signet::OAuth2::Client.new(client_options)
    client.code = params[:code]
    response = client.fetch_access_token!
    client.update!(response)

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    free_busy_request = Google::Apis::CalendarV3::FreeBusyRequest.new
    free_busy_request.time_min = DateTime.now
    free_busy_request.time_max = DateTime.now + 5.days
    free_busy_request.time_zone = "EST"
    free_busy_request_item = Google::Apis::CalendarV3::FreeBusyRequestItem.new
    free_busy_request_item.id = "primary"
    free_busy_request.items = [ free_busy_request_item ]

    free_busy = service.query_freebusy(free_busy_request)

    @events = service.list_events("primary").items
    @busys = free_busy.calendars["primary"].busy.map { |busy| { start: busy.start, end: busy.end } }

    # rescue Google::Apis::AuthorizationError
    # response = client.refresh!

    # session[:authorization] = session[:authorization].merge(response)

    # retry
  end

  private

  def client_options
    {
      client_id: ENV["GOOGLE_CALENDAR_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CALENDAR_CLIENT_SECRET"],
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
      redirect_uri: ENV["CALLBACK_URL"]
    }
  end
end
