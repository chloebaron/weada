require 'open-uri'
require 'json'

class WeatherConditionsController < ApplicationController

  def index
    get_weather_conditions_in_json
  end

  # def sunny?
  #   temperature >= 15.0,
  #   apparent_temperature >= 15.0,
  #   cloud_cover <= .20,
  #   wind_speed <= 15.0,
  #   precip_probability <= .20,
  #   precip_type = :precip_type,
  # end

  private

  def get_weather_conditions_in_json
    user_address = User.first.address

    geo_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{user_address}&key=#{ENV["GOOGLE_API_LEO"]}"
    geo_json = open(geo_url).read
    geocode = JSON.parse(geo_json)
    geo_location = geocode["results"][0]["geometry"]["location"]

    weather_url = "https://api.darksky.net/forecast/#{ENV["DARKSKY_API_LEO"]}/#{geo_location['lat']},#{geo_location['lng']}"
    weather_json = open(weather_url).read
    $weather = JSON.parse(weather_json)

    $seven_day_cycle = [$weather["daily"]["data"]]
  end
end

