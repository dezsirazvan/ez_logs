class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :event_id
      t.string :correlation_id
      t.string :event_type
      t.string :resource
      t.string :action
      t.string :actor
      t.json :metadata
      t.datetime :timestamp

      t.timestamps
    end
  end
end
