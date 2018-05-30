require 'open-uri'
require 'json'

namespace :forecast do
  desc "TODO"
  task next_120_hours_for_montreal: :environment do
    HourlyWeather.destroy_all

    geo_url = "https://maps.googleapis.com/maps/api/geocode/json?address=Montreal,QC&key=#{ENV["GOOGLE_API_LEO"]}"
    geo_json = open(geo_url).read
    geocode = JSON.parse(geo_json)
    geo_location = geocode["results"][0]["geometry"]["location"]

    weather_url = "https://api.darksky.net/forecast/#{ENV["DARKSKY_API_LEO"]}/#{geo_location['lat']},#{geo_location['lng']}?extends=hourly&exclude=daily,minutely"
    weather_json = open(weather_url).read
    weather = JSON.parse(weather_json)

    next_120_hours = weather["hourly"]["data"].slice(0..120)

    # temperature in degrees F
    # windspeed in miles per hour
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
end
