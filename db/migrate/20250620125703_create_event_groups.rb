class CreateEventGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :event_groups do |t|
      t.string :name
      t.text :description
      t.decimal :similarity_threshold
      t.string :group_hash
      t.boolean :is_active

      t.timestamps
    end
  end
end
