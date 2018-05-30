# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# If you have your own seed please comment blow
# User.create(email: "admin@admin.com", password: "testing", admin: true)
# User.create(email: "user@user.com", password: "testing")
Activity.destroy_all
User.destroy_all


User.create!(
  email: "test1@test.com",
  password: "testing",
  first_name: "bob",
  last_name: "bobson",
  address: " 5333 Avenue Casgrain #102, Montréal, QC H2T 1X6".strip.gsub(/\s+/, " ").gsub(/(\(|\)|\#)/, "").unicode_normalize(:nfkd).encode('ASCII', replace: '')
  )

<<<<<<< HEAD
user_address = User.first.address

geo_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{user_address}&key=#{ENV["GEOCODE_API_LEO"]}"
geo_json = open(geo_url).read
geocode = JSON.parse(geo_json)
geo_location = geocode["results"][0]["geometry"]["location"]

weather_url = "https://api.darksky.net/forecast/#{ENV["DARKSKY_API_LEO"]}/#{geo_location['lat']},#{geo_location['lng']}"
weather_json = open(weather_url).read
weather = JSON.parse(weather_json)

seven_day_cycle = [weather["daily"]["data"]]

seven_day_cycle[0].each do |weather_condition|
  date_day = Time.at(weather_condition["time"]).day
  WeatherCondition.create!(
  location: user_address,
  temperature: weather_condition["temperatureHigh"],
  apparent_temperature: weather_condition["apparentTemperatureHigh"],
  cloud_cover: weather_condition["cloudCovers"].to_f,
  wind_speed: weather_condition["windSpeed"].to_f,
  precip_probability: weather_condition["precipProbability"].to_f,
  precip_type: weather_condition["precipType"],
  day: date_day
  )
end
=======
# geo_url = "https://maps.googleapis.com/maps/api/geocode/json?address=Montreal,QC&key=#{ENV["GOOGLE_API_LEO"]}"
# geo_json = open(geo_url).read
# geocode = JSON.parse(geo_json)
# geo_location = geocode["results"][0]["geometry"]["location"]

# weather_url = "https://api.darksky.net/forecast/#{ENV["DARKSKY_API_LEO"]}/#{geo_location['lat']},#{geo_location['lng']}"
# weather_json = open(weather_url).read
# weather = JSON.parse(weather_json)

# next_168_hours = [weather["hourly"]["data"]]

# next_168_hours.each do |weather_condition|
#   HourlyWeather.create!(
#   temperature: weather_condition["temperatureHigh"],
#   apparent_temperature: weather_condition["apparentTemperatureHigh"],
#   cloud_cover: weather_condition["cloudCover"],
#   wind_speed: weather_condition["windSpeed"],
#   precip_probability: weather_condition["precipProbability"],
#   precip_type: weather_condition["precipType"],
#   time: weather_condition["time"]
#   )
# end
>>>>>>> 19323c3c733aeda909aece088ec19c14ec3d6966

