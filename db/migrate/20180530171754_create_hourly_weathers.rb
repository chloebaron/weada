class CreateHourlyWeathers < ActiveRecord::Migration[5.2]
  def change
    create_table :hourly_weathers do |t|
      t.float :temperature
      t.float :apparent_temperature
      t.float :cloud_cover
      t.float :wind_speed
      t.float :precip_probability
      t.datetime :time

      t.timestamps
    end
  end
end
