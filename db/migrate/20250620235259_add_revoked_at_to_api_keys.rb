class AddRevokedAtToApiKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :api_keys, :revoked_at, :datetime
  end
end
