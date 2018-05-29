class AddDayToWeatherConditions < ActiveRecord::Migration[5.2]
  def change
    add_column :weather_conditions, :day, :integer
  end
end
