class AddWorkEndTimeToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :work_end_time, :string
  end
end
