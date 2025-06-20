class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.string :resource_type
      t.string :resource_id
      t.json :details
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
