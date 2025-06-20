class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.json :permissions, default: {}
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :roles, :name, unique: true
    add_index :roles, :is_active
  end
end
