class ChangeActivities < ActiveRecord::Migration[5.2]
  def change
    change_table :activities do |t|
      t.string :name
      t.remove :category, :weather_condition
      t.boolean :sunny_required
      t.boolean :warm_required
      t.boolean :dry_required
      t.boolean :calm_required
    end
  end
end
