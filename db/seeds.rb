# User.create(email: "admin@admin.com", password: "testing", admin: true)
# User.create(email: "user@user.com", password: "testing")
Activity.destroy_all
User.destroy_all


User.create!(
  email: "test1@test.com",
  password: "testing",
  first_name: "bob",
  last_name: "bobson",
  address: " 5333 Avenue Casgrain #102, Montréal, QC H2T 1X6" #.strip.gsub(/\s+/, " ").gsub(/(\(|\)|\#)/, "").unicode_normalize(:nfkd).encode('ASCII', replace: '')
  )


{
  "run" => {
    name: "Go for a run",
    sunny_required: false,
    warm_required: false,
    dry_required: true,
    calm_required: true
  },
  "park" => {
    name: "Spend time in the park",
    sunny_required: true,
    warm_required: true,
    dry_required: true,
    calm_required: true
  },
  "museum" => {
    name: "Go to a Museum",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false,
  },
  "bbq" => {
    name: "Have a Barbeque",
    sunny_required: false,
    warm_required: true,
    dry_required: true,
    calm_required: true
  },
  "yoga" => {
    name: "Do a Yoga video",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false
  },
  "cinema" => {
    name: "Go to the Cinema",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false
  },
  "drinks" => {
    name: "Drinks on a Terrace",
    sunny_required: true,
    warm_required: true,
    dry_required: true,
    calm_required: true
  },
  "read" => {
    name: "Read a Book",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false
  },
  "gallery" => {
    name: "Check out an Art Gallery",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false
  },
  "Sit in a cafe" => {
    name: "Sit in a cafe",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false
  }
}.values.each do |e|
 Activity.create(e)
end

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


