class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name
      t.text :description
      t.json :permissions
      t.boolean :is_active

      t.timestamps
    end
  end
end
