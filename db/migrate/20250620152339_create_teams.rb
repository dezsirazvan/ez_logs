class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.text :description
      t.references :company, null: false, foreign_key: true
      t.json :settings, default: {}
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
  end
end
