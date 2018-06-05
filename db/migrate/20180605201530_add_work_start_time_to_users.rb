class AddWorkStartTimeToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :work_start_time, :string
  end
end
