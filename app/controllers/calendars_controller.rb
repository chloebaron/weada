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
    # Not necessary to rename, but rename can be more clear
    @busys_seperated = seperate_busys_by_date(@busys_seperated)
    @availibilities = availibilities(@busys_seperated)
    filtered = filtered_by_duration(@availibilities, duration_input)
    determine_time_slot(filtered, duration_input, activity)
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

  def seperate_busys_by_date(busys)
    current_day = DateTime.now.day
    new_busys = []
    for current_day in current_day..(busys.last[:start].day)
      new_busys << busys.select { |busy| busy[:start].day == current_day }
      current_day += 1
    end
    new_busys
  end

  def calculate_time(availibility)
    ((availibility[:end] - availibility[:start]) * 24 * 60).to_f
  end
#preference
  def filtered_by_duration(availibilities, duration_input)
      filtered = availibilities.flatten.select do |availibility|
        calculate_time(availibility) >= duration_input
      end
  end

  def event_weathers(event)
    event_weathers = HourlyWeather.all.select do |w|
      w.time - w.time.to_datetime.minute.minute >= event[:start] && w.time <= event[:end]
    end
    event_weathers
  end

  def all_event_weathers_good?(event_weathers, activity)
    event_weathers.all? { |e| activity.permitted_under_weather(e) }
  end

  # attempt to set event by moving forward the start time in a new hour, eg.
  # previous attempt start time is 8: 40, next attempt start time would be 9:00
  # instead of moving forward in a fixed amount
  # the point is to check through all weather conditions during an event
  def move_forward(event, duration_input)
    a = 60 - event[:start].minute
    event[:start] += a.minute
    event[:start] -= even[start:].second
    event[:end] += duration_input.minute
    event
  end

  def event_h(f, duration_input)
    { start: f[:start], end: f[:start] + duration_input.minute }
  end

  # find all posibilities in one slot
  def each_slot(f, duration_input, activity)
    event = event_h(f, duration_input) # => { start: , end:  }
    event_weathers(event)
    events = []
    until event[:end] > f[:end]
      if all_event_weathers_good?(event_weathers, activity)
        events << event
      else
        move_forward(event, duration_input)
      end
    end
    events # => [...]
  end

  # find all free time slot that is suitable for acvity
  def all_slot(filtered, duration_input, activity)
    all = []
    filtered.each do |f|
      all << each_slot(f, duration_input, activity) unless each_slot(f, duration_input, activity).empty?
    end
    all # => [[..], [...] ]
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
