class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.text :description
      t.string :domain
      t.json :settings, default: {}
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
  end
end
