class AddPrecipTypeToHourlyWeathers < ActiveRecord::Migration[5.2]
  def change
    add_column :hourly_weathers, :precip_type, :string
  end
end
