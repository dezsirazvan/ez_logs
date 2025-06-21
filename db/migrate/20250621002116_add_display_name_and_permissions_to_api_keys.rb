class AddDisplayNameAndPermissionsToApiKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :api_keys, :display_name, :string
    add_column :api_keys, :can_read, :boolean
    add_column :api_keys, :can_write, :boolean
    add_column :api_keys, :can_delete, :boolean
  end
end
