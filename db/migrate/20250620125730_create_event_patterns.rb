class CreateEventPatterns < ActiveRecord::Migration[8.0]
  def change
    create_table :event_patterns do |t|
      t.string :name
      t.json :pattern
      t.text :description
      t.boolean :is_active

      t.timestamps
    end
  end
end
