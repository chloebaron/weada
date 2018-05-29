require 'open-uri'
require 'json'

class WeatherConditionsController < ApplicationController
  def show
    @seven_day_cycle = WeatherCondition.all
  end

  def new

  end

  def create
    # @user_address = User.find(1).address

    # geo_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{@user_address}&key=#{ENV[:GEOCODE_API_LEO]}"
    # geo_json = open(geo_url).read
    # geocode = JSON.parse(geo_json)
    # geo_location = geocode.location

    # weather_url = "https://api.darksky.net/forecast/#{ENV[:DARKSKY_API_LEO]}/#{geo_location.lat},#{geo_location.lng}"
    # weather_json = open(weather_url).read
    # weather = JSON.parse(weather_json)

    # seven_day_cycle = [weather.daily.data]

    # seven_day_cycle[0].each do |weather_condition|
    #   date_day = Time.at(weather_condition.time).day
    #   WeatherCondition.create!(
    #     location: @user_address,
    #     temperature: weather_condition.temperature,
    #     apparent_temperature: weather_condition.apparentTemperature,
    #     cloud_cover: weather_condition.cloudCover,
    #     wind_speed: weather_condition.windSpeed,
    #     precip_probability: weather_condition.precipProbability,
    #     precip_type: weather_condition.preciptype,
    #     day: date_day
    #     )
    end

  end

  def edit
  end

  def update
  end
end
