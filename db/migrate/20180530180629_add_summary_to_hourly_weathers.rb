class AddSummaryToHourlyWeathers < ActiveRecord::Migration[5.2]
  def change
    add_column :hourly_weathers, :summary, :string
  end
end
