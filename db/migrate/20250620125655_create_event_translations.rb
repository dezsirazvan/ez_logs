class CreateEventTranslations < ActiveRecord::Migration[8.0]
  def change
    create_table :event_translations do |t|
      t.references :event, null: false, foreign_key: true
      t.text :translated_text
      t.string :ai_model
      t.string :ai_version
      t.decimal :confidence
      t.string :cache_hash
      t.datetime :expires_at

      t.timestamps
    end
  end
end
