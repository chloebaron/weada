class CreateWeatherConditions < ActiveRecord::Migration[5.2]
  def change
    create_table :weather_conditions do |t|
      t.string :location
      t.float :temperature
      t.float :apparent_temperature
      t.float :cloud_cover
      t.float :wind_speed
      t.float :precip_probability
      t.string :precip_type

      t.timestamps
    end
  end
end
