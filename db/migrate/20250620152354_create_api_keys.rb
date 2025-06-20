class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.references :company, null: false, foreign_key: true
      t.string :token, null: false
      t.string :name
      t.text :description
      t.datetime :expires_at
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
  end
end
