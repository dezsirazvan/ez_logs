class AddFieldsToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :settings, :json
    add_column :teams, :is_active, :boolean, default: true
    add_reference :teams, :owner, null: false, foreign_key: { to_table: :users }
  end
end
