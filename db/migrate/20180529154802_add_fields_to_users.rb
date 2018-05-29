class AddFieldsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :wake_up_hour, :time
    add_column :users, :sleep_hour, :time
    add_column :users, :calendar_id, :string
    add_column :users, :address, :string
  end
end
