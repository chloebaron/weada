class Activity < ApplicationRecord
  has_many :user_events
  has_many :users

  # Given some weather, can you do this activity?
  def permitted_under_weather(hourly_weather)

    # running = Activity.create(
    #   sunny_required: true,
    #   calm_required: false,
    #   dry_required: true,
    #   warm_required: false
    # )

    # running.permitted_under_weather(Weather.first)

    (hourly_weather.sunny? || !sunny_required) &&
    (hourly_weather.calm?  || !calm_required)  &&
    (hourly_weather.warm?  || !warm_required)  &&
    (hourly_weather.dry?   || !dry_required)
  end
end


