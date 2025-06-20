class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :company, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :action, null: false
      t.string :actor_type
      t.string :actor_id
      t.string :subject_type
      t.string :subject_id
      t.string :severity
      t.string :source
      t.string :tags
      t.json :metadata
      t.datetime :timestamp, null: false

      t.timestamps
    end
  end
end
