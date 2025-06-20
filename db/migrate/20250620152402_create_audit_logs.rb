class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :company, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :action
      t.json :details

      t.timestamps
    end
  end
end
