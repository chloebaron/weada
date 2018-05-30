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
    @busys = seperate_busys_by_date(@busys)
    @availibilities = availibilities(@busys)
    determine_time_slot(@availibilities, 30)
    raise
  end
  def availibilities(busys)
    availibilities = []
    busys.each do |busy|
      date = busy[0][:start]
      i = 0
      a = []
      a << after_wake_up(busy, date)
      while i < busy.length - 1
        a << { start: busy[i][:end], end: busy[i + 1][:start] }
        i += 1
      end
      a << before_sleep(busy, date)
      availibilities << a
    end
    availibilities
  end

  def after_wake_up(busy, date)
    wake_up = DateTime.new(date.year, date.month, date.day, 8, 0, 0, '-04:00')
    { start: wake_up, end: busy[0][:start] }
  end

  def before_sleep(busy, date)
    _sleep = DateTime.new(date.year, date.month, date.day, 22, 0, 0, '-04:00')
    { start: busy.last[:end], end: _sleep  }
  end

  # def free_time_duration(availibilities)
  #   availibilities.map { |availibility| ((availibility[:start] - availibility[:end]) * -24 * 60).to_f  }
  # end

  def seperate_busys_by_date(busys)
    day = DateTime.now.day
    i = 1
    new_busys = []
    for day in day..(busys.last[:start].day)
      new_busys << busys.select { |busy| busy[:start].day == day }
      day += 1
    end
    new_busys
  end

  def determine_time_slot(availibilities, duration_input)
    filtered = availibilities.flatten.select do |availibility|
      calculate_time(availibility) >= duration_input
    end
  # We can only check the start_time weahter condition and end_time weather condition
    filtered.each do |f|
      f[:start] + duration_input.minutes
    end
  end

  def calculate_time(availibility)
    ((availibility[:end] - availibility[:start]) * 24 * 60).to_f
  end

    # rescue Google::Apis::AuthorizationError
    # response = client.refresh!

    # session[:authorization] = session[:authorization].merge(response)

    # retry

  private

  def client_options
    {
      client_id: ENV["GOOGLE_CALENDAR_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CALENDAR_CLIENT_SECRET"],
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
      redirect_uri: "http://localhost:3000/callback"
    }
  end
end
