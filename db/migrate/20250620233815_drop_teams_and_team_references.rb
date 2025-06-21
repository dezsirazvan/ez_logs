class DropTeamsAndTeamReferences < ActiveRecord::Migration[8.0]
  def change
    # Remove foreign keys and columns first
    remove_foreign_key :users, :teams if foreign_key_exists?(:users, :teams)
    remove_column :users, :team_id if column_exists?(:users, :team_id)
    remove_column :users, :team_notifications if column_exists?(:users, :team_notifications)

    remove_foreign_key :invitations, :teams if foreign_key_exists?(:invitations, :teams)
    remove_column :invitations, :team_id if column_exists?(:invitations, :team_id)

    # Now drop the teams table
    drop_table :teams, if_exists: true
  end
end
