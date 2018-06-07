class HourlyWeather < ApplicationRecord
  def sunny?
    cloud_cover <= 0.20
  end

  def dry?
    precip_probability <= 0.20 && temperature > 32.0
  end

  def calm?
    wind_speed <= 15.0
  end

  def warm?
    apparent_temperature >= 60.0
  end
end
