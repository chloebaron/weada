class AddPreferenceToActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :activities, :preference, :integer
  end
end
