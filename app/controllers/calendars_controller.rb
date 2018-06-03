class CalendarsController < ApplicationController
  before_action :get_client_session, only: [:list_calendars, :create_weada_calendar, :insert_weada_event]

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
    free_busy_weada = get_free_busy_weada(service)
    # @events = service.list_events("primary").items
    @busys = free_busy.calendars["primary"].busy.map { |busy| { start: busy.start, end: busy.end } }
    @busys_weada = free_busy_weada.calendars["Weada"].busy.map { |busy| { start: busy.start, end: busy.end } }
    convert_time_zone(@busys)
    convert_time_zone(@busys_weada)

    params = { user_events: {"2"=>"200", "3"=>"30", "4"=>"30", "5"=>"30", "6"=>"200", "7"=>"120", "8"=>"30", "9"=>"30", "10"=>"30", "11"=>"30"},
    activity_ids: ["6", "2", "7"]}
    @selected_activities = []
    params[:activity_ids].each do |id|
      @selected_activities << { activity: Activity.find(id), duration: params[:user_events]["#{id}"].to_i }
    end
    @new_busys = @busys
    @selected_activities.sort_by! { |activity| activity[:activity].preference }
    @placed_activities = []
    @selected_activities.each do |activity|
      @new_busys.sort_by!{ |busy| busy[:start] }
      @new_busys_seperated = seperate_busys_by_date(@new_busys)
      @availibilities = availibilities(@new_busys_seperated)
      @availibilities += free_day_availibilities(@new_busys, 8, 22)
      # byebug
      filtered = filtered_by_duration(@availibilities, activity[:duration])
      if filtered.empty?
        placed_activity_hash = recommend_longest_suitable_time_slot_from_all_availibilities(@availibilities, activity)
        placed_activity_hash[:activity] = activity[:activity]
        @placed_activities << placed_activity_hash
        @new_busys << recommend_longest_suitable_time_slot_from_all_availibilities(@availibilities, activity)
      else
        @a = all_possibilities_in_all_availibilities_interval(filtered, activity[:duration], activity[:activity])
        @b = all_possibilities_in_all_availibilities_duration(filtered, activity[:duration], activity[:activity])
        @all_possibilities_insert_event = mix(@a, @b)
        if @all_possibilities_insert_event.empty?
          placed_activity_hash = recommend_longest_suitable_time_slot_from_all_availibilities(@availibilities, activity) unless recommend_longest_suitable_time_slot_from_all_availibilities(@availibilities, activity).nil?
          placed_activity_hash[:activity] = activity[:activity]
          @placed_activities << placed_activity_hash
        else
          placed_activity_hash = @all_possibilities_insert_event.first
          placed_activity_hash[:activity] = activity[:activity]
          @placed_activities << placed_activity_hash
        end
        @new_busys << @all_possibilities_insert_event.first
      end
    end


    user_weada_events = @placed_activities.map do |placed_activity|
    UserEvent.create!(
      start_time: placed_activity[:start],
      end_time: placed_activity[:end],
      activity_id: placed_activity[:activity].id,
      user_id: current_user.id,
      duration: calculate_time({ start: placed_activity[:start], end: placed_activity[:end]})
       )
    end
    create_weada_calendar(client) unless list_calendars(client).any? { |list| list.summary.downcase == "weada" }
    user_weada_events.each { |e| insert_weada_event(e, client) }
    # redirect_to calendars_url
  end

    # if selected activities not equal to palced_activities,
    # we will ask user if he wanna adjust to see if there might be

  def create_weada_calendar(client)
    get_service_methods(client)

    weada_calendar = Google::Apis::CalendarV3::Calendar.new(
    summary: 'Weada',
    time_zone: 'EST'
  )
   @weada_calendar = @service.insert_calendar(weada_calendar)
  end


  def insert_weada_event(user_weada_event, client)
    get_service_methods(client)
    list_calendars(client)

    event = Google::Apis::CalendarV3::Event.new({
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: user_weada_event.start_time.to_datetime),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: user_weada_event.end_time.to_datetime),
      summary: user_weada_event.activity.name
    })

    weada_calendar = @calendar_list.find {|calendar| calendar.summary == "Weada"}

    @service.insert_event(weada_calendar.id, event)
  end





###################################--METHODS FOR FINDING AVAILABLE TIME--#################################
   # It will dynamically change the time zone between EST and EDT
   def convert_time_zone(busys)
    busys.each do |busy|
      time_zone = ActiveSupport::TimeZone.new("Eastern Time (US & Canada)")
      busy[:start] = busy[:start].to_time.in_time_zone(time_zone).to_datetime
      busy[:end] = busy[:end].to_time.in_time_zone(time_zone).to_datetime
    end
   end

  def availibilities(busys)
    busys.reject! { |busy| busy.empty? }
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
    if current_date_time > wake_up && current_date_time < busy[0][:start]
      { start: current_date_time, end: busy[0][:start] }
    elsif current_date_time <= wake_up && busy[0][:start] > wake_up
      { start: wake_up, end: busy[0][:start] }
    end
  end

  def before_sleep(busy, date)
    _sleep = DateTime.new(date.year, date.month, date.day, 22, 0, 0, '-04:00')
    current_date_time = DateTime.now
    if current_date_time < _sleep  && current_date_time > busy.last[:end]
      { start: cuurent_date_time, end: _sleep }
    elsif current_date_time <= busy.last[:end] && _sleep < busy.last[:end]
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
    availibilities.flatten.select do |availibility|
      calculate_time(availibility) >= duration_input
    end
  end



###################################--METHODS FOR FINDING SUITABLE WEATHER CONDITIONS--#################################
  def event_weathers(event)
    HourlyWeather.all.select do |w|
      w.time >= event[:start] - event[:start].minute.minute && w.time <= event[:end]
    end
  end

  def each_interval_weather(interval_time_slot)
    HourlyWeather.all.select do |w|
      w.time.to_datetime == interval_time_slot[:start] -= interval_time_slot[:start].minute.minute
    end
  end

  def all_event_weathers_good?(event_weathers_a, activity)
    event_weathers_a.all? { |e| activity.permitted_under_weather(e) }
    true
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

  def event_hash(f, duration_input)
    { start: f[:start], end: f[:start] + duration_input.minute }
  end

  # find all posibilities in one slot
  # find all posibilities to insert events by moving forward in interval
  def all_possibilities_in_each_availibility_interval(f, duration_input, activity)
    event = event_hash(f, duration_input) # => { start: , end:  }
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
  def all_possibilities_in_each_availibility_duration(f, duration_input, activity)
    event = event_hash(f, duration_input) # => { start: , end:  }
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
  def all_possibilities_in_all_availibilities_interval(filtered, duration_input, activity)
    all = []
    filtered.each do |f|
      each = all_possibilities_in_each_availibility_interval(f, duration_input, activity)
      all <<  each unless each.empty?
    end
    all.flatten # => [[..], [...] ]
  end

  def all_possibilities_in_all_availibilities_duration(filtered, duration_input, activity)
    all = []
    filtered.each do |f|
      each = all_possibilities_in_each_availibility_duration(f, duration_input, activity)
      all << each unless each.empty?
    end
    all.flatten # => [[..], [...] ]
  end

  def mix(interval, duration)
    (interval + duration).uniq.sort_by! { |e| e[:start] } # e => hash
  end


  def get_all_interval_time_slot_in_one_availibility(availibility)
    all_in_one_availibility = []
    interval_time_slot = { start: availibility[:start], end: availibility[:start] + (60 - availibility[:start].minute).minute }
    all_in_one_availibility << { start: availibility[:start], end: availibility[:start] + (60 - availibility[:start].minute).minute }
    while interval_time_slot[:end] < availibility[:end]
      if (availibility[:end] - interval_time_slot[:end]).hour > 1
        interval_time_slot[:start] = interval_time_slot[:end]
        interval_time_slot[:end] += 1.hour

      elsif (availibility[:end] -  interval_time_slot[:end]).hour < 1 && (availibility[:end] -  interval_time_slot[:end]).hour >0
        interval_time_slot[:start] = interval_time_slot[:end]
        interval_time_slot[:end] = availibility[:end]

      end
      all_in_one_availibility << { start: interval_time_slot[:start], end: interval_time_slot[:end] }

    end
    all_in_one_availibility
  end

  # def move_a(interval_time_slot, availibility)
  #   interval_time_slot[:start] = interval_time_slot[:end]
  #   interval_time_slot[:end] += 1.hour

  # end

  # def move_b(interval_time_slot, availibility)
  #   interval_time_slot[:start] = interval_time_slot[:end]
  #   interval_time_slot[:end] = availibility[:end]
  #   interval_time_slot
  # end

  # def merge_all_squent_suitable_time_slots_in_each_availibility(suitable_interval_time_slots)
  #   merged_all_squent_suitable_time_slots = []
  #     suitable_interval_time_slots.each_with_index do |e, index|
  #       byebug
  #       if !suitable_interval_time_slots[index + 1].nil?
  #         if e[:end] >= suitable_interval_time_slots[index + 1][:start]
  #           e[:end] = suitable_interval_time_slots[index + 1][:end]
  #           merged_all_squent_suitable_time_slots << e
  #         else
  #           merged_all_squent_suitable_time_slots << e
  #         end
  #       end
  #     end
  #     merged_all_squent_suitable_time_slots

  # end

  def merge_all_squent_suitable_time_slots_in_each_availibility(suitable_interval_time_slots)
    i = 0
    until suitable_interval_time_slots[i + 1].nil?
      # byebug
      if suitable_interval_time_slots[i][:end] >= suitable_interval_time_slots[i + 1][:start]
        suitable_interval_time_slots[i][:end] = suitable_interval_time_slots[i + 1][:end]
        suitable_interval_time_slots.delete_at(i + 1)
      else
        i += 1
      end
    end
    suitable_interval_time_slots
  end

  def recommend_longest_suitable_time_slot_from_all_availibilities(availibilities, activity)
    all_candidates_from_each_merged = []
    availibilities.each do |availibility|
      @all_in_one_availibility = get_all_interval_time_slot_in_one_availibility(availibility)
      suitable_interval_time_slots = @all_in_one_availibility.select do |e|
        all_event_weathers_good?(each_interval_weather(e), activity)
      end
      @a = merge_all_squent_suitable_time_slots_in_each_availibility(suitable_interval_time_slots)
      all_candidates_from_each_merged << find_longest_suitale_time_slot_from_one_merged(@a) unless find_longest_suitale_time_slot_from_one_merged(@a).nil?
    end
    all_candidates_from_each_merged.sort_by! { |e| e[:end] - e[:start] }.last

  end

  def find_longest_suitale_time_slot_from_one_merged(merged_all_squent_suitable_time_slots)
    merged_all_squent_suitable_time_slots.sort_by! { |e| e[:end] - e[:start] }.last
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

  def list_calendars(client)
    get_service_methods(client)

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
  end

  def get_free_busy_weada(calendar_service)
    free_busy_request = Google::Apis::CalendarV3::FreeBusyRequest.new
    free_busy_request.time_min = DateTime.now
    free_busy_request.time_max = DateTime.now + 5.days
    free_busy_request.time_zone = "EST"
    free_busy_request_item = Google::Apis::CalendarV3::FreeBusyRequestItem.new
    free_busy_request_item.id = "Weada"
    free_busy_request.items = [ free_busy_request_item ]
    calendar_service.query_freebusy(free_busy_request)
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
