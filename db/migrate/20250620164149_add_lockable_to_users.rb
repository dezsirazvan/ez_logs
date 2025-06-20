class AddLockableToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
  end
end
