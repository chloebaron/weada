class CalendarsController < ApplicationController
  def redirect
    client = Signet::OAuth2::Client.new(client_options)
    redirect_to client.authorization_uri.to_s
  end

  def display_weada_calendar
    require 'google/apis/calendar_v3'
    require 'google/api_client/client_secrets.rb'

    secrets = Google::APIClient::ClientSecrets.new({
      "web" => {
        "refresh_token" => current_user.refresh_token,
        "client_id" => ENV["GOOGLE_CLIENT_ID"],
        "client_secret" => ENV["GOOGLE_CLIENT_SECRET"]
      }
    })

    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = secrets.to_authorization
    @service.authorization.refresh!
    # get_client_session # => @client
    find_weada_calendar() # => @weada_calendar

    @id = @weada_calendar.id
  end

  def callback
    # require 'google/apis/calendar_v3'
    # require 'google/api_client/client_secrets.rb'

    # current_user.generate_activites

    # secrets = Google::APIClient::ClientSecrets.new({
    #   "web" => {
    #     "refresh_token" => current_user.refresh_token,
    #     "client_id" => ENV["GOOGLE_CLIENT_ID"],
    #     "client_secret" => ENV["GOOGLE_CLIENT_SECRET"]
    #   }
    # })

    # @service = Google::Apis::CalendarV3::CalendarService.new
    # @service.authorization = secrets.to_authorization
    # @service.authorization.refresh!


    # client = Signet::OAuth2::Client.new(client_options)
    # client.code = params[:code]

    # response = client.fetch_access_token!

    redirect_to generate_calendar_path
    # check private method "place_holder" for test code
  end

    # if selected activities not equal to placed_activities,
    # we will ask user if he wanna adjust to see if there might be

  def create_weada_calendar()
    # get_service_methods(client)

    weada_calendar = Google::Apis::CalendarV3::Calendar.new(
    summary: 'Weada',
    time_zone: 'EST'
    )

   @weada_calendar = @service.insert_calendar(weada_calendar)
  end


  def insert_weada_event(user_weada_event)
    # get_service_methods(client)
    weada_calendar = list_calendars().find{ |e| e.summary == "Weada" }

    event = Google::Apis::CalendarV3::Event.new(
      summary: "#{user_weada_event.activity.description}",
      start: {
        date_time: "#{user_weada_event.start_time.to_datetime}",
        time_zone: 'America/Toronto',
      },
      end: {
        date_time: "#{user_weada_event.end_time.to_datetime}",
        time_zone: 'America/Toronto',
      }
    )

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

  def datetime_before_wakeup?(datetime, days_wakeup_time)
    datetime < days_wakeup_time
  end

  def datetime_after_bedtime?(datetime, days_bedtime)
    datetime > days_bedtime
  end

  def availability_is_within_waking_hours?(availability, wakeup_time, bedtime)
    !datetime_before_wakeup?(availability[:start], wakeup_time) &&
    !datetime_after_bedtime?(availability[:end], bedtime)
  end

  def wakeup_time(date)
    user_time = current_user.wake_up_hour.to_datetime
    minutes = user_time.minute.to_s.split("").map { |number| number.to_i }
    DateTime.new(date.year, date.month, date.day, user_time.hour, minutes[0], 0, '-04:00')
  end

  def bedtime(date)
    user_time = current_user.sleep_hour.to_datetime
    minutes = user_time.minute.to_s.split("").map { |number| number.to_i }
    DateTime.new(date.year, date.month, date.day, user_time.hour, minutes[0], 0, '-04:00')
  end

  def availabilities(days_of_busies) # => array of the times you are available in order of day
    days_of_busies.reject! { |busy| busy.empty? }
    availabilities = []
    days_of_busies.each do |busies|
      date = busies.first[:start]
      availabilities_for_day = []
      unless free_time_after_wake_up(busies, date).nil?
        availabilities_for_day << free_time_after_wake_up(busies, date)
      end

      busies.each_with_index do |busy, index|
        if busies[index + 1].nil?
          start_time = busy[:end]
          end_time = bedtime(date)
        else
          start_time = busy[:end]
          end_time =  busies[index + 1][:start]
        end

        if availability_is_within_waking_hours?(
          {start: start_time, end: end_time},
          wakeup_time(date),
          bedtime(date)
        )
          availabilities_for_day << { start: start_time, end: end_time }
        end
      availabilities << availabilities_for_day
      end

      unless free_time_before_sleep(busies, date).nil?
        availabilities_for_day << free_time_before_sleep(busies, date)
      end

     end

    availabilities.flatten
  end

  def free_day_availabilities(days_of_busies, wake_up_hour, sleep_hour)
    free_day_availabilities = []
    date_time = DateTime.now
    i = 1
    for i in 1..5
        unless days_of_busies.any? { |busies| busies.first[:start].day == date_time.day }
          if i == 1
            free_day_availabilities << { start: DateTime.now, end: bedtime(date_time) }
          else
            free_day_availabilities << { start: wakeup_time(date_time), end: bedtime(date_time) }
          end
        end
      i += 1
      date_time += 1.day
    end
    free_day_availabilities
  end

  def generate_date_time(current_time, hour)
    DateTime.new(current_time.year, current_time.month, current_time.day, hour.to_i, 0, 0, '-04:00')
  end

  def between_wake_up_and_work_start(date_time)
    start = DateTime.new(date_time.year, date_time.month, date_time.day, current_user.wake_up_hour.to_i, 0, 0, '-04:00')
    _end = DateTime.new(date_time.year, date_time.month, date_time.day, current_user.work_start_time.to_i, 0, 0, '-04:00')
    { start: start, end: _end }
  end

  def between_work_end_and_sleep(date_time)
    start = DateTime.new(date_time.year, date_time.month, date_time.day, current_user.work_end_time.to_i, 0, 0, '-04:00')
    _end = DateTime.new(date_time.year, date_time.month, date_time.day, current_user.sleep_hour.to_i, 0, 0, '-04:00')
    { start: start, end: _end }
  end

  def have_jobs?
    !current_user.work_start_time.nil?
  end

  def week_days?(date_time)
    !["Saturday", "Sunday"].include? convert_to_day_of_week(date_time.cwday)
  end


  def convert_to_day_of_week(cwday)
    weekday_hash = { 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4=> "Thursday", 5 => "Friday", 6 => "Saturday", 7 => "Sunday"}
    weekday_hash[cwday]
  end

  def free_time_after_wake_up(busy, date)
    wake_up = DateTime.new(date.year, date.month, date.day, 8, 0, 0, '-04:00')
    current_date_time = DateTime.now
    if current_date_time >= wake_up && current_date_time < busy[0][:start] # see if the current start time is a viable start time
      { start: current_date_time, end: busy[0][:start] }
    elsif current_date_time <= wake_up && busy[0][:start] > wake_up # if not then the start time will be whenever they wake up
      { start: wake_up, end: busy[0][:start] }
    end
  end

  def free_time_before_sleep(busy, date)
    _sleep = DateTime.new(date.year, date.month, date.day, 22, 0, 0, '-04:00')
    current_date_time = DateTime.now
    if current_date_time < _sleep  && current_date_time > busy.last[:end]
      { start: current_date_time, end: _sleep } # see if the current time is a suitable start time
    elsif current_date_time <= busy.last[:end] && _sleep < busy.last[:end] # if not then the time their last event ends will be their start time
      { start: busy.last[:end], end: _sleep }
    end
  end

  def seperate_busys_by_date(busys)
    busys.group_by { |busy| busy[:start].day }.values
  end

  def calculate_time(availability)
    ((availability[:end] - availability[:start]) * 24 * 60).to_f # => minutes
  end

  def filtered_by_duration(user_availabilities, duration_input) # find the free times that are longer than the user given duration for an activity
    user_availabilities.flatten.select do |availability|
      calculate_time(availability) >= duration_input
    end # => array of availabilites longer than or equal to the length of an activity
  end



###################################--METHODS FOR FINDING SUITABLE WEATHER CONDITIONS--#################################
  def event_weathers(event)
    HourlyWeather.all.select do |w|
      w.time >= event[:start] - event[:start].minute.minute && w.time <= event[:end]
    end
  end

  def get_weather_at_interval(interval_time_slot) # => all hourly weathers whose hour matches the hour of the interval
    HourlyWeather.all.select do |hourly_weather|
      hourly_weather.time.to_datetime == interval_time_slot[:start] -= interval_time_slot[:start].minute.minute
    end
  end

  def all_event_weathers_good?(event_weathers_a, activity) # => returns all events that are true for 'permitted_under_weather()'
    event_weathers_a.all? { |e| activity.permitted_under_weather(e) }
  end




###################################--METHODS FOR FINDING POSITION IN SUITABLE WEATHER SLOT--#################################
  # attempt to set event by moving forward the start time in a new hour, eg.
  # previous attempt start time is 8: 40, next attempt start time would be 9:00
  # instead of moving forward in a fixed amount
  # the point is to check through all weather conditions during an event
  def move_forward_to_next_interval(event, duration_input)
    minutes_from_one_hour = 60 - event[:start].minute
    event[:start] += minutes_from_one_hour.minute # move forward into next hour
    event[:start] -= event[:start].second.second
    event[:end] = event[:start] + duration_input.minute
    event
  end

  def move_forward_by_duration(event, duration_input)
    event[:start] += duration_input.minute
    event[:start] -= event[:start].second.second
    event[:end] = event[:start] + duration_input.minute
    event
  end

  def event_hash(event, duration_input)
    { start: event[:start], end: event[:start] + duration_input.minute }
  end

  # find all posibilities in one slot
  # find all posibilities to insert events by moving forward in interval
  def all_possibilities_in_each_availability_interval(f, duration_input, activity)
    event = event_hash(f, duration_input) # => { start: , end:  }
    events = []
    while event[:end] < f[:end]
      if all_event_weathers_good?(event_weathers(event), activity)
        events << {start: event[:start], end: event[:end] }
      end
      event = move_forward_to_next_interval(event, duration_input)
    end
    events # => [...]
  end

  # find all posibilities to insert events by movinfg forward in duration
  def all_possibilities_in_each_availability_duration(f, duration_input, activity) # maybe we shoudl get rid of the end time option in the user activity?
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

  # find all free time slot that is suitable for activity
  def all_possibilities_in_all_availabilities_interval(filtered, duration_input, activity)
    all = []
    filtered.each do |f|
      each = all_possibilities_in_each_availability_interval(f, duration_input, activity)
      all <<  each unless each.empty?
    end
    all.flatten # => [[..], [...] ]
  end

  def all_possibilities_in_all_availabilities_duration(filtered, duration_input, activity)
    all = []
    filtered.each do |f|
      each = all_possibilities_in_each_availability_duration(f, duration_input, activity)
      all << each unless each.empty?
    end
    all.flatten # => [[..], [...] ]
  end

  def combine_possibilities(interval, duration)
    (interval + duration).uniq.sort_by! { |event| event[:start] } # e => hash
  end

  # Doesn't take weather into account
  def get_all_interval_time_slot_in_one_availability(availability) # sets intervals of time within one availability
    all_in_one_availability = []
    interval_time_slot = { start: availability[:start], end: availability[:start] + (60 - availability[:start].minute).minute }
    all_in_one_availability << { start: availability[:start], end: availability[:start] + (60 - availability[:start].minute).minute }
    while interval_time_slot[:end] < availability[:end]
      if availability[:end] - interval_time_slot[:end] > 1.hour # what if the difference is equal to an hour?
        interval_time_slot[:start] = interval_time_slot[:end]
        interval_time_slot[:end] += 1.hour # make the interval an hour long if it is greater than 1 hour
      elsif availability[:end] - interval_time_slot[:end] < 1.hour && availability[:end] - interval_time_slot[:end] > 0
        # if time is less than 1hour, but can still fit within the availablity then...
        interval_time_slot[:start] = interval_time_slot[:end]
        interval_time_slot[:end] = availability[:end] # make the interval last until the availability ends
      end
      all_in_one_availability << { start: interval_time_slot[:start], end: interval_time_slot[:end] }
    end
    all_in_one_availability # array of intervals within one availability
  end

  def merge_all_squent_suitable_time_slots_in_each_availability(suitable_interval_time_slots)
    i = 0
    until suitable_interval_time_slots[i + 1].nil?
      if suitable_interval_time_slots[i][:end] >= suitable_interval_time_slots[i + 1][:start]
        suitable_interval_time_slots[i][:end] = suitable_interval_time_slots[i + 1][:end]
        suitable_interval_time_slots.delete_at(i + 1)
      else
        i += 1
      end
    end
    suitable_interval_time_slots
  end

  # Takes weather into account
  def recommend_longest_suitable_time_slot_from_all_availabilities(availabilities, activity)
    all_candidates_from_each_merged = []
    availabilities.each do |availability|
      @all_in_one_availability = get_all_interval_time_slot_in_one_availability(availability)
      suitable_interval_time_slots = @all_in_one_availability.select do |e|
        all_event_weathers_good?(get_weather_at_interval(e), activity)
      end
      @a = merge_all_squent_suitable_time_slots_in_each_availability(suitable_interval_time_slots)
      all_candidates_from_each_merged << find_longest_suitale_time_slot_from_one_merged(@a) unless find_longest_suitale_time_slot_from_one_merged(@a).nil?
    end
    # binding.pry
    all_candidates_from_each_merged.sort_by! { |e| e[:end] - e[:start] }.last
  end

  def find_longest_suitale_time_slot_from_one_merged(merged_all_squent_suitable_time_slots) # => the longest free time slot
    merged_all_squent_suitable_time_slots.sort_by! { |e| e[:end] - e[:start] }.last
  end

  # rescue Google::Apis::AuthorizationError
  # response = client.refresh!

  # session[:authorization] = session[:authorization].merge(response)

  # retry

  def get_calendar_id
    page_token = nil
    begin
      result = @service.list_calendar_lists(page_token: page_token)
      result.items.each do |e|
        print e.summary + "\n"
      end
      if result.next_page_token != page_token
        page_token = result.next_page_token
      else
        page_token = nil
      end
    end while !page_token.nil?
    result.items
  end

  private


  def delete_weada_calendar
    list_calendars # this function provides the @calendar_list array

    weada_calendars = @calendar_list.find_all {|calendar| calendar.summary == "Weada"}
    # raise
    weada_calendars.each { |weada_calendar| @service.delete_calendar_list(weada_calendar.id) }
  end

  def list_calendars
    # get_service_methods(client)

    @calendar_list = @service.list_calendar_lists.items
  end

  def find_weada_calendar()
    list_calendars()
    @weada_calendar = @calendar_list.find {|calendar| calendar.summary == "Weada"}
    @weada_calendar
  end

  # def get_client_session
  #   @client = Signet::OAuth2::Client.new(client_options)
  #   @client.update!(session[:authorization])
  #   @client
  # end

  # def get_service_methods(client)
  #   @service = Google::Apis::CalendarV3::CalendarService.new
  #   @service.authorization = client
  # end

  def get_free_busy(id = "primary")
    free_busy_request = Google::Apis::CalendarV3::FreeBusyRequest.new
    free_busy_request.time_min = DateTime.now
    free_busy_request.time_max = DateTime.now + 5.days
    free_busy_request.time_zone = "EST"
    free_busy_request_item = Google::Apis::CalendarV3::FreeBusyRequestItem.new
    free_busy_request_item.id = id
    free_busy_request.items = [ free_busy_request_item ]
    @service.query_freebusy(free_busy_request)
  end

  # def client_options
  #   {
  #     client_id: ENV["GOOGLE_CALENDAR_CLIENT_ID"],
  #     client_secret: ENV["GOOGLE_CALENDAR_CLIENT_SECRET"],
  #     authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
  #     token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
  #     scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
  #     redirect_uri: callback_url
  #   }
  # end

  # def place_holder
  #   # Originally connected to the callback method

  #   @ids = get_calendar_id()
  #   weada_calendar = @ids.find { |id| id.summary == "Weada" }
  #   weada_calendar ||= create_weada_calendar()

  #   free_busy = get_free_busy()
  #   #debugger
  #   free_busy_weada = get_free_busy_weada(weada_calendar.id)
  #   # @events = service.list_events("primary").items

  #   # busy items from primary
  #   @busys = free_busy.calendars["primary"].busy.map { |busy| { start: busy.start, end: busy.end } }

  #   # if weada calendar exists, get busy items from that, else just don't
  #   @busys_weada = free_busy_weada.calendars[weada_calendar.id].busy.map { |busy| { start: busy.start, end: busy.end } }

  #   convert_time_zone(@busys)

  #   # if we have a weada schedule then...
  #   convert_time_zone(@busys_weada)


  #   # combine all the busy events
  #   @new_busys = (@busys + @busys_weada).sort_by! { |busy| busy[:start] }

  #   # ???
  #   @selected_activities = UserEvent.joins(:activity).where(status: 0).order("activities.preference desc")

  #   # @selected_activities.sort_by! { |user_event| user_event.activity.preference }

  #   @selected_activities.each do |user_event|
  #     @new_busys.sort_by!{ |busy| busy[:start] }

  #     # group activities by date
  #     @new_busys_seperated = seperate_busys_by_date(@new_busys)

  #     # get availabilities for the week
  #     @availabilities = availabilities(@new_busys_seperated)

  #     # add the availbilities of the days where there are no activities
  #     @availabilities += free_day_availabilities(@new_busys_seperated, current_user.wake_up_hour.to_i, current_user.sleep_hour.to_i)

  #     # find the activities that can fit within the time slots of availabilities
  #     filtered = filtered_by_duration(@availabilities, user_event.duration)

  #     if filtered.empty? # if there is no activity that is shorter than available free time then...

  #       time_slot = recommend_longest_suitable_time_slot_from_all_availabilities(@availabilities, user_event.activity)

  #       # user_event.update(duration: calculate_time(time_slot))

  #       # update the user event
  #       user_event.update(start_time: time_slot[:start], end_time: time_slot[:end], duration: calculate_time(time_slot), status: 1)

  #       # Add the longest possuble time slot for that activity to @new_busys, for updating the calendar
  #       @new_busys << recommend_longest_suitable_time_slot_from_all_availabilities(@availabilities, user_event.activity)
  #     else
  #       @interval_slot_possiblilities = all_possibilities_in_all_availabilities_interval(filtered, user_event.duration, user_event.activity)
  #       @duration_slot_possiblilities = all_possibilities_in_all_availabilities_duration(filtered, user_event.duration, user_event.activity)
  #       @all_possibilities_insert_event = combine_possibilities(@interval_slot_possiblilities, @duration_slot_possiblilities)

  #       if @all_possibilities_insert_event.empty?
  #         time_slot = unless recommend_longest_suitable_time_slot_from_all_availabilities(@availabilities, user_event.activity).nil?
  #           recommend_longest_suitable_time_slot_from_all_availabilities(@availabilities, user_event.activity)
  #         end

  #         user_event.update(duration: calculate_time(time_slot))
  #         user_event.update(start_time: time_slot[:start], end_time: time_slot[:end], status: 1)
  #       else
  #         time_slot = @all_possibilities_insert_event.first
  #         user_event.update(duration: calculate_time(time_slot))
  #         user_event.update(start_time: time_slot[:start], end_time: time_slot[:end], status: 1)
  #       end
  #       @new_busys << @all_possibilities_insert_event.first
  #     end
  #   end

  #   # OLD CODE #
  #     # user_weada_events = @placed_activities.map do |placed_activity|
  #     # UserEvent.create!(
  #     #   start_time: placed_activity[:start],
  #     #   end_time: placed_activity[:end],
  #     #   activity_id: placed_activity.activity.id,
  #     #   user_id: current_user.id,
  #     #   duration: calculate_time({ start: placed_activity[:start], end: placed_activity[:end]})
  #     #    )
  #     # end
  #     # create_weada_calendar(client) unless list_calendars(client).any? { |list| list.summary.downcase == "weada" }
  #   # <--------------------------------> #


  #   @selected_activities.each { |e| insert_weada_event(e) }
  #   # redirect_to calendars_url
  # end
end
