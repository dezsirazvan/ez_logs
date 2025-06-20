class CreateAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :alerts do |t|
      t.string :name
      t.text :description
      t.string :alert_type
      t.string :severity
      t.json :conditions
      t.boolean :enabled
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
