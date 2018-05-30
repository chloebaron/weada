class Activity < ApplicationRecord
  has_many :user_events
  has_many :users

  # Given some weather, can you do this activity?
  def permitted_under_weather(weather)

    # running = Activity.create(
    #   sunny_required: true,
    #   calm_required: false,
    #   dry_required: true,
    #   warm_required: false
    # )

    # running.permitted_under_weather(Weather.first)

    (weather.sunny? || !sunny_required) &&
    (weather.calm?  || !calm_required)  &&
    (weather.warm?  || !warm_required)  &&
    (weather.dry?   || !dry_required)
  end
end


