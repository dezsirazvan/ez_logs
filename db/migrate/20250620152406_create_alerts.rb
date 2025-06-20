class CreateAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :alerts do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :severity
      t.boolean :is_active

      t.timestamps
    end
  end
end
