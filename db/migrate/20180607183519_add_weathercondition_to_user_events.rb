class AddWeatherconditionToUserEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :user_events, :weather_condition, :string
  end
end
