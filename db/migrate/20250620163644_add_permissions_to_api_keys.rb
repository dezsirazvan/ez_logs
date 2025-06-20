class AddPermissionsToApiKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :api_keys, :permissions, :json, default: {}
  end
end
