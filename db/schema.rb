# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_06_21_003342) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "company_id", null: false
    t.string "action"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "ip_address"
    t.string "user_agent"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_activities_on_company_id"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "alerts", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.text "description"
    t.string "severity"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_alerts_on_company_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "token", null: false
    t.string "name"
    t.text "description"
    t.datetime "expires_at"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "permissions", default: {}
    t.datetime "last_used_at"
    t.datetime "revoked_at"
    t.string "display_name"
    t.boolean "can_read"
    t.boolean "can_write"
    t.boolean "can_delete"
    t.index ["company_id"], name: "index_api_keys_on_company_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "user_id"
    t.string "action"
    t.json "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_audit_logs_on_company_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "domain"
    t.json "settings", default: {}
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "event_type", null: false
    t.string "action", null: false
    t.string "severity"
    t.string "source"
    t.string "tags"
    t.json "metadata"
    t.datetime "timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "event_id"
    t.string "correlation_id"
    t.json "actor"
    t.json "subject"
    t.json "correlation"
    t.json "correlation_context"
    t.json "payload"
    t.json "platform"
    t.json "validation_errors", default: []
    t.index ["company_id"], name: "index_events_on_company_id"
    t.index ["correlation_id"], name: "index_events_on_correlation_id"
    t.index ["event_id"], name: "index_events_on_event_id", unique: true
    t.index ["timestamp"], name: "index_events_on_timestamp"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "role_id", null: false
    t.bigint "invited_by_id", null: false
    t.string "email", null: false
    t.string "status", default: "pending", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_invitations_on_company_id"
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["expires_at"], name: "index_invitations_on_expires_at"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["role_id"], name: "index_invitations_on_role_id"
    t.index ["status"], name: "index_invitations_on_status"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.json "permissions", default: {}
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_roles_on_is_active"
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "user_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string "ip_address"
    t.text "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password"
    t.string "first_name"
    t.string "last_name"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "role_id"
    t.datetime "confirmed_at"
    t.boolean "mfa_enabled", default: false, null: false
    t.string "two_factor_secret"
    t.json "backup_codes", default: []
    t.boolean "email_notifications", default: true, null: false
    t.boolean "alert_notifications", default: true, null: false
    t.string "timezone", default: "UTC", null: false
    t.string "language", default: "en", null: false
    t.integer "login_count", default: 0
    t.datetime "last_login_at"
    t.integer "failed_login_attempts", default: 0
    t.datetime "locked_at"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.boolean "is_active", default: true, null: false
    t.string "unconfirmed_email"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["confirmed_at"], name: "index_users_on_confirmed_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["locked_at"], name: "index_users_on_locked_at"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "activities", "companies"
  add_foreign_key "activities", "users"
  add_foreign_key "alerts", "companies"
  add_foreign_key "api_keys", "companies"
  add_foreign_key "audit_logs", "companies"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "events", "companies"
  add_foreign_key "invitations", "companies"
  add_foreign_key "invitations", "roles"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "users", "companies"
  add_foreign_key "users", "roles"
end
