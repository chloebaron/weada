class UserEventsController < CalendarsController
  before_action :authenticate_user!, only: [:create, :dashboard]
  before_action :set_event, only: [:edit, :update]
  before_action :following_five_days, only: :dashboard

  def new
    @user_event = UserEvent.new
  end

  def create
    # Destroy last pending user_events records
    UserEvent.where(status: 0).destroy_all
    params[:user_events].keys.each do |activity_id|
      activity = Activity.find(activity_id.to_i)

      if params[:user_events][activity_id] != ""
        UserEvent.create!(user: current_user, activity: activity, status: 0, duration: params[:user_events][activity_id].to_i)
      end
    end


    redirect_to generate_calendar_path
  end

  # METHODS USED ARE PRIVATE #
  def generate_calendar
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

    get_hourly_forecasts if HourlyWeather.all.empty? # => fills database with forecasts if data base is empty

    # get_client_session # => @client
    # get_service_methods() # => @service
    get_weada_calendar # => @weada_calendar

    free_busy = get_free_busy() # => free busy object

    free_busy_weada = get_free_busy(@weada_calendar.id) # => free busy object

    @busys = free_busy.calendars["primary"].busy.map { |busy| { start: busy.start, end: busy.end } }

    # busy items from primary

    # busy items from Weada calendar, if it exists
    @busys_weada = free_busy_weada.calendars[@weada_calendar.id].busy.map { |busy| { start: busy.start, end: busy.end } }

    convert_time_zone(@busys)

    convert_time_zone(@busys_weada)

    combine_weada_and_primary_buys(@busys, @busys_weada) # => @new_busys

    get_availabilities(@new_busys) # => @availabilities

    # order by user preference
    # @selected_activities = UserEvent.joins(:activity).where(status: 0).order("activities.preference desc")

    get_chosen_activities # => @selected_activities

    find_best_times_for_chosen_activities(@selected_activities, @new_busys, @availabilities)
    # raise

    # Insert event into Weada calendar
    @selected_activities.each { |user_event| insert_weada_event(user_event, ) }

    redirect_to dashboard_path
  end


  def edit
    # @eventevent.id?
  end

  def update
    @events = UserEvent.where(user: current_user, status: 0)

    @events.each do |event|
      event.update(duration: params[:user_events][event.id.to_s])
    end

    redirect_to dashboard_path
  end

  def duration
    @events = UserEvent.where(user: current_user, status: 0)
  end

  def dashboard
    @time_zone = ActiveSupport::TimeZone.new("Eastern Time (US & Canada)")
  end

  private

  def following_five_days
    five_days_user_events = UserEvent.where("user_id = ? AND start_time >= ? AND start_time <= ?",
      current_user.id,
      DateTime.now,
      DateTime.now + 4.day
      )
    five_days_user_events = five_days_user_events.group_by { |user_event| user_event.start_time.day }.values
    five_days_user_events.sort_by! { |user_events| user_events.first.start_time }
    @schedule_hash = {}
    for i in 0..4
      correspond_day_user_events = five_days_user_events.find{ |user_events| user_events.first.start_time.day == (DateTime.now + i.day).day }

      @schedule_hash[convert_to_day_of_week((DateTime.now + i.day).cwday)] = correspond_day_user_events || ""
      i += 1
    end
    @schedule_hash
  end

  def event_params
    params.permit(:activity_ids)
  end

  def set_event
    @event = UserEvent.find_by(id: params[:id])
  end



  # METHODS USED (IN ORDER) FOR THE 'generate_calendar' METHOD #

  def get_hourly_forecasts
    HourlyWeather.destroy_all

    weather_url = "https://api.darksky.net/forecast/#{ENV["DARKSKY_API_LEO"]}/45.516136,-73.656830?extend=hourly&exclude=daily,minutely"
    weather_json = open(weather_url).read
    weather = JSON.parse(weather_json)
    next_120_hours = weather["hourly"]["data"].slice(0..119)

    next_120_hours.each do |weather_condition|
      HourlyWeather.create!(
      summary: weather_condition["summary"],
      temperature: weather_condition["temperature"],
      apparent_temperature: weather_condition["apparentTemperature"],
      cloud_cover: weather_condition["cloudCover"],
      wind_speed: weather_condition["windSpeed"],
      precip_probability: weather_condition["precipProbability"],
      precip_type: weather_condition["precipType"],
      time: Time.at(weather_condition["time"])
      )
    end
  end

  def get_weada_calendar
    ids = get_calendar_id
    @weada_calendar = ids.find { |id| id.summary == "Weada" }
    @weada_calendar ||= create_weada_calendar()
    # raise
  end

  def combine_weada_and_primary_buys(primary_busys, weada_busys)
    @new_busys = (primary_busys + weada_busys).sort_by! { |busy| busy[:start] }
    @new_busys
  end

  def work_start_time(date)
    DateTime.new(date.year, date.month, date.day, current_user.work_start_time.to_i, 0, 0)
  end

  def work_end_time(date)
    DateTime.new(date.year, date.month, date.day, current_user.work_end_time.to_i, 0, 0)
  end


  def new_availabilities_with_work(availabilities)
    grouped_availabilities =  group_availabilities(availbilities)
    grouped_availabilities.each do |_availabilities|
      if week_days?(availabilities.first[:start])
        _availabilities.reject! { |availability| during_work_hours?(availability) }
        _availabilities.each do |availability|
          if end_touch_busy?(availability)
            availability[:end] = generate_date_time(availability[:end],current_user.work_start_time)
          elsif head_touch_busy?(availability)
            availability[:start] = generate_date_time(availability[:start], current_user.work_end_time)
          elsif across_busy?(availability)
            _availabilities << { start: availability[:start], end: generate_date_time(availability[:start], current_user.work_start_time)}
            _availabilities << { start: generate_date_time(availability[:end], current_user.work_end_time), end: availability[:end] }
            _availabilities.sort_by! { |_availability| _availability[:start] }
          end
        end
      end
    end
    group_availabilities.flatten.sort_by! { |_availability| _availability[:start] }
  end

  def during_work_hours?(availability)
    availability[:start].hour >= current_user.work_start_tim.to_i && availability[:end].hour <= current_user.work_end_time.to_i
  end

  def end_touch_busy?(availability)
    availability[:start].hour < current_user.work_start_time.to_i&& availability[:end].hour <= current_user.work_end_time.to_i
  end

  def head_touch_busy?(availability)
    availability[:start].hour >= current_user.work_start_tim.to_i && availability[:end].hour > current_user.work_end_time.to_i
  end

  def across_busy?(availability)
    availability[:start].hour < current_user.work_start_time.to_i&& availability[:end].hour > current_user.work_end_time.to_i
  end

  def group_availabilities(availabilities)
    availabilities.group_by { |availability| availability[:start].day }.values
  end

  def get_availabilities(new_busys)
    new_busys.sort_by!{ |busy| busy[:start] }
    # group activities by date
    new_busys_seperated = seperate_busys_by_date(new_busys)
    # get availabilities for the week
    @availabilities = availabilities(new_busys_seperated)

    # add the availbilities of the days where there are no activities
    @availabilities += free_day_availabilities(new_busys_seperated, current_user.wake_up_hour.to_i, current_user.sleep_hour.to_i)
  end

  def find_optimal_availabilities(availabilities, user_event)
    # find the activities that can fit within the time slots of availabilities
    @filtered = filtered_by_duration(availabilities, user_event.duration)
    @filtered
  end

  def get_chosen_activities
    events = UserEvent.all
    @selected_activities = events.find_all { |event| event.user_id == current_user.id && event.status == 0 }
    # @selected_activities = [UserEvent.create(user: current_user, activity: Activity.first, duration: 60)]
    @selected_activities.each do |user_event|
      user_event.update duration: user_event.duration + 30
    end
  end

  def find_best_times_for_chosen_activities(selected_activities, new_busys, availabilities)
    selected_activities.each do |user_event|
      availabilities = get_availabilities(new_busys)

      find_optimal_availabilities(availabilities, user_event)
      if @filtered.empty?
        time_slot = recommend_longest_suitable_time_slot_from_all_availabilities(availabilities, user_event.activity)

        # update the user event
        user_event.update(start_time: time_slot[:start] + 15.minutes, end_time: time_slot[:end], duration: calculate_time(time_slot) - 30, status: 1)

        # Add new event to busys sp that it's taken into consideration when the next event is added
        new_busys << recommend_longest_suitable_time_slot_from_all_availabilities(availabilities, user_event.activity)
      else
        @interval_slot_possiblilities = all_possibilities_in_all_availabilities_interval(@filtered, user_event.duration, user_event.activity)
        @duration_slot_possiblilities = all_possibilities_in_all_availabilities_duration(@filtered, user_event.duration, user_event.activity)
        @all_possibilities_insert_event = combine_possibilities(@interval_slot_possiblilities, @duration_slot_possiblilities)

        if @all_possibilities_insert_event.empty?
          time_slot = recommend_longest_suitable_time_slot_from_all_availabilities(availabilities, user_event.activity)  unless recommend_longest_suitable_time_slot_from_all_availabilities(@availabilities, user_event.activity).nil?
          user_event.update(duration: calculate_time(time_slot) - 30)
          user_event.update(start_time: time_slot[:start] + 15.minutes, end_time: time_slot[:end], status: 1)
        else
          time_slot = @all_possibilities_insert_event.sample
          user_event.update(duration: calculate_time(time_slot) - 30)
          user_event.update(start_time: time_slot[:start] + 15.minutes, end_time: time_slot[:end], status: 1)
        end

        # Add new event to busys sp that it's taken into consideration when the next event is added
        new_busys << time_slot
      end
    end
  end
# <---------------------------------------> #
end

# HARD CODED TEST FOR INSERTING EVENTS #

  # weada_events = []
  # i = 1
  # @user_events.each do |event|
  #    hard coding for testing purposes, this is not how it will actually be implemented
  #   event.start_time = DateTime.now + i.hour
  #   event.end_time = event.start_time + event.duration.minute
  #   event.save!
  #   weada_events << event
  #   i += 1
  # end


  # weada_events.each do |event|
  #   insert_weada_event(event, @client)
  # end
# @user_events = events.find_all { |event| event.user_id == current_user.id && event.status == 0 }
