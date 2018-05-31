class WeatherCondition < ApplicationRecord
  def sunny?
    cloud_cover <= 0.20
  end

  def dry?
    precip_probability <= 0.20 && temperature > 0
  end

  def calm?
    wind_speed <= 15.0
  end

  def warm?
    apparent_temperature >= 15.0
  end
end
