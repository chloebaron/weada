class AddStatusToUserEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :user_events, :status, :integer
  end
end
