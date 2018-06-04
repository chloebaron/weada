class UserEventsController < CalendarsController
  before_action :authenticate_user!, only: [:create]
  before_action :set_event, only: [:edit, :update]

  def new
    @user_event = UserEvent.new
  end

  def create
    # Destroy last pending user_events records
    UserEvent.where(status: 0).destroy_all
    params[:activity_ids].each do |activity_id|
      activity = Activity.find(activity_id)
      UserEvent.create!(user: current_user, activity: activity, status: 0, duration: params[:user_events][activity_id].to_i)
    end
    redirect_to redirect_path
  end

  def generate_calendar
    get_client_session
    create_weada_calendar(@client)

    events = UserEvent.all

    @user_events = events.find_all { |event| event.user_id == current_user.id && event.status == 0 }

    weada_events = []

    i = 1
    @user_events.each do |event|
       # hard coding for testing purposes, this is not how it will actually be implemented
      event.start_time = DateTime.now + i.hour
      event.end_time = event.start_time + event.duration.minute
      event.save!

      weada_events << event
      i += 1
    end


    weada_events.each do |event|
      insert_weada_event(event, @client)
    end

    raise

    redirect_to dashboard_path
  end

  def place_events(event, client)

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
    @events = UserEvent.where(user: current_user, status: 0)
  end

  # def destroy
  # end

  private

  def event_params
    params.permit(:activity_ids)
  end

  def set_event
    @event = UserEvent.find_by(id: params[:id])
  end
end
