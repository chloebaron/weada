class CalendarsController < ApplicationController
  before_action :get_client_session, only: [:list_calendars, :create_weada_calendar]

  def redirect
    client = Signet::OAuth2::Client.new(client_options)
    redirect_to client.authorization_uri.to_s
  end

  def callback
    client = Signet::OAuth2::Client.new(client_options)
    client.code = params[:code]

    response = client.fetch_access_token!

    session[:authorization] = response

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    free_busy = get_free_busy(service)

    @events = service.list_events("primary").items
    @busys = free_busy.calendars["primary"].busy.map { |busy| { start: busy.start, end: busy.end } }
    # Not necessary to rename, but rename can be more clear

    # filtered = filtered_by_duration(@availibilities)
    # , duration_input when implemented properly
    # determine_time_slot(filtered, duration_i
    @busys_seperated = seperate_busys_by_date(@busys)
    @availibilities = availibilities(@busys_seperated)
    @availibilities += free_day_availibilities(@busys, 8, 22)
    filtered = filtered_by_duration(@availibilities, 30)

    @selected_activities = [Activity.find(2), Activity.find(3), Activity.find(4)]

    @placed_activities = []
    @before = @busys
    @selected_activities.each do |activity|
      @busys_seperated = seperate_busys_by_date(@busys)
      @availibilities = availibilities(@busys_seperated)
      filtered = filtered_by_duration(@availibilities, 30)
      @a = all_slot(filtered, 30, activity)
      @b = all_slot_b(filtered, 30, activity)
      @c = mix(@a, @b)
      byebug
      @placed_activities << @c.first
      @busys << @c.first
      # should implement the insert event call for api here???????
      @new_busys = @busys.sort_by!{ |busy| busy[:start] }
    end
    # redirect_to calendars_url
  end



  def create_weada_calendar
    get_service_methods(@client)

    weada_calendar = Google::Apis::CalendarV3::Calendar.new(
    summary: 'Weada',
    time_zone: 'EST'
  )
   @weada_calendar = calendar_service.insert_calendar(weada_calendar)
  end


  def insert_weada_event(user_weada_event)
    list_calendars

    event = Google::Apis::CalendarV3::Event.new({
      start: Google::Apis::CalendarV3::EventDateTime.new(user_weada_event.start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(user_weada_event.end_time),
      summary: user_weada_event.activity.name
    })

    weada_calendar = @calendar_list.find {|calendar| calendar.summary == "Weada"}

    @service.insert_event(weada_calendar.id, event)
  end





###################################--METHODS FOR FINDING AVAILABLE TIME--#################################
  def availibilities(busys)
    availibilities = []
    busys.each do |busy|
      date = busy[0][:start]
      i = 0
      availibilities_for_day = []
      availibilities_for_day << after_wake_up(busy, date) unless after_wake_up(busy, date).nil?
      while i < busy.length - 1
        availibilities_for_day << { start: busy[i][:end], end: busy[i + 1][:start] }
        i += 1
      end
      availibilities_for_day << before_sleep(busy, date) unless before_sleep(busy, date).nil?
      availibilities << availibilities_for_day
    end
    availibilities.flatten
  end

  def free_day_availibilities(busys, wake_up_hour, sleep_hour)
    current_day = DateTime.now
    free_day_availibilities_array = []
    free_days_num = (current_day + 4.day).mjd - busys.last[:start].mjd
    last_busy_day = busys.last[:start]
    i = 1
    for i in 1..free_days_num
      wake_up = DateTime.new(last_busy_day.year, last_busy_day.month, last_busy_day.day, wake_up_hour, 0, 0, '-4:00') + i.day
      _sleep = DateTime.new(last_busy_day.year, last_busy_day.month, last_busy_day.day, sleep_hour, 0, 0, '-4:00') + i.day
      free_day_availibilities_array << { start: wake_up, end: _sleep  }
      i += 1
    end
    free_day_availibilities_array
  end

  def after_wake_up(busy, date)
    wake_up = DateTime.new(date.year, date.month, date.day, 8, 0, 0, '-04:00')
    current_date_time = DateTime.now
    if current_date_time >= wake_up && current_date_time < busy[0][:start]
      { start: current_date_time, end: busy[0][:start] }
    elsif current_date_time < wake_up
      { start: wake_up, end: busy[0][:start] }
    end
  end

  def before_sleep(busy, date)
    _sleep = DateTime.new(date.year, date.month, date.day, 22, 0, 0, '-04:00')
    current_date_time = DateTime.now
    if current_date_time < _sleep  && current_date_time > busy.last[:end]
      { start: cuurent_date_time, end: _sleep }
    elsif current_date_time <= busy.last[:end]
      { start: busy.last[:end], end: _sleep }
    end
  end

  def seperate_busys_by_date(busys)
    current_day = DateTime.now
    new_busys = []
    # for current_day in current_day..(busys.last[:start].day)
    until current_day > busys.last[:end]
      new_busys << busys.select { |busy| busy[:start].day == current_day.day }
      current_day += 1
    end
    new_busys
  end

  def calculate_time(availibility)
    ((availibility[:end] - availibility[:start]) * 24 * 60).to_f # => minutes
  end

  def filtered_by_duration(availibilities, duration_input)
    filtered = availibilities.flatten.select do |availibility|
      calculate_time(availibility) >= duration_input
    end
  end



###################################--METHODS FOR FINDING SUITABLE WEATHER CONDITIONS--#################################
  def event_weathers(event)
    event_weathers_a = HourlyWeather.all.select do |w|
      w.time - w.time.to_datetime.minute.minute >= event[:start] && w.time <= event[:end]
    end
    event_weathers_a # =>[...]
  end

  def all_event_weathers_good?(event_weathers_a, activity)
    event_weathers_a.all? { |e| activity.permitted_under_weather(e) }
  end




###################################--METHODS FOR FINDING POSITION IN SUITABLE WEATHER SLOT--#################################
  # attempt to set event by moving forward the start time in a new hour, eg.
  # previous attempt start time is 8: 40, next attempt start time would be 9:00
  # instead of moving forward in a fixed amount
  # the point is to check through all weather conditions during an event
  def move_forward(event, duration_input)
    a = 60 - event[:start].minute
    event[:start] += a.minute
    event[:start] -= event[:start].second
    event[:end] = event[:start] + duration_input.minute
    event
  end

  def move_forward_by_duration(event, duration_input)
    event[:start] += duration_input.minute
    event[:start] -= event[:start].second
    event[:end] = event[:start] + duration_input.minute
    event
  end

  def event_h(f, duration_input)
    { start: f[:start], end: f[:start] + duration_input.minute }
  end

  # find all posibilities in one slot
  # find all posibilities to insert events by moving forward in interval
  def each_slot(f, duration_input, activity)
    event = event_h(f, duration_input) # => { start: , end:  }
    events = []
    while event[:end] < f[:end]
      if all_event_weathers_good?(event_weathers(event), activity)
        events << {start: event[:start], end: event[:end] }
      end
        event = move_forward(event, duration_input)
    end
    events # => [...]
  end
  # find all posibilities to insert events by movinfg forward in duration
  def each_slot_b(f, duration_input, activity)
    event = event_h(f, duration_input) # => { start: , end:  }
    events = []
    while event[:end] < f[:end]
      if all_event_weathers_good?(event_weathers(event), activity)
        events << {start: event[:start], end: event[:end] }
      end
        event = move_forward_by_duration(event, duration_input)
    end
    events # => [...]
  end


  # find all free time slot that is suitable for acvity
  def all_slot(filtered, duration_input, activity)
    all = []
    filtered.each do |f|
      all << each_slot(f, duration_input, activity) unless each_slot(f, duration_input, activity).empty?
    end
    all.flatten # => [[..], [...] ]
  end

  def all_slot_b(filtered, duration_input, activity)
    all = []
    filtered.each do |f|
      all << each_slot_b(f, duration_input, activity) unless each_slot_b(f, duration_input, activity).empty?
    end
    all.flatten # => [[..], [...] ]
  end

  def mix(all_slot, all_slot_b)
    (all_slot + all_slot_b).uniq.sort_by! { |e| e[:start]}# e => hash
  end

  # another big challenge
  # what if there is no suitable slot?
  # We might ajust the duration to see if there is any suitable slot



  # rescue Google::Apis::AuthorizationError
  # response = client.refresh!

  # session[:authorization] = session[:authorization].merge(response)

  # retry

  private


  def delete_weada_calendar
    list_calendars
    weada_calendars = @calendar_list.find_all {|calendar| calendar.summary == "Weada"}
    raise
    weada_calendars.each { |weada_calendar| @service.delete_calendar_list(weada_calendar.id) }
  end

  def list_calendars
    get_service_methods(@client)

    @calendar_list = @service.list_calendar_lists.items
  end

  def get_client_session
    @client = Signet::OAuth2::Client.new(client_options)
    @client.update!(session[:authorization])
    @client
  end

  def get_service_methods(client)
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = client
  end


  def get_free_busy(calendar_service)
    free_busy_request = Google::Apis::CalendarV3::FreeBusyRequest.new
    free_busy_request.time_min = DateTime.now
    free_busy_request.time_max = DateTime.now + 5.days
    free_busy_request.time_zone = "EST"
    free_busy_request_item = Google::Apis::CalendarV3::FreeBusyRequestItem.new
    free_busy_request_item.id = "primary"
    free_busy_request.items = [ free_busy_request_item ]

    free_busy = calendar_service.query_freebusy(free_busy_request)

    free_busy
  end

  def client_options
    {
      client_id: ENV["GOOGLE_CALENDAR_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CALENDAR_CLIENT_SECRET"],
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
      redirect_uri: callback_url
    }
  end
end
