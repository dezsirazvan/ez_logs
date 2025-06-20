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

ActiveRecord::Schema[8.0].define(version: 2025_06_20_133120) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alerts", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "alert_type"
    t.string "severity"
    t.json "conditions"
    t.boolean "enabled"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_alerts_on_user_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "key_hash"
    t.json "permissions"
    t.datetime "last_used_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "action"
    t.string "resource_type"
    t.string "resource_id"
    t.json "details"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "event_groups", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "similarity_threshold"
    t.string "group_hash"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "event_patterns", force: :cascade do |t|
    t.string "name"
    t.json "pattern"
    t.text "description"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "event_translations", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.text "translated_text"
    t.string "ai_model"
    t.string "ai_version"
    t.decimal "confidence"
    t.string "cache_hash"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_translations_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "event_id"
    t.string "correlation_id"
    t.string "event_type"
    t.string "resource"
    t.string "action"
    t.string "actor"
    t.json "metadata"
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invitations", force: :cascade do |t|
    t.string "email"
    t.bigint "team_id", null: false
    t.bigint "role_id", null: false
    t.bigint "invited_by_id", null: false
    t.string "status"
    t.datetime "expires_at"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["role_id"], name: "index_invitations_on_role_id"
    t.index ["team_id"], name: "index_invitations_on_team_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.json "permissions"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "settings"
    t.boolean "is_active", default: true
    t.bigint "owner_id", null: false
    t.index ["owner_id"], name: "index_teams_on_owner_id"
    t.index ["user_id"], name: "index_teams_on_user_id"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "session_token"
    t.datetime "expires_at"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.bigint "role_id", null: false
    t.bigint "team_id"
    t.string "avatar"
    t.string "two_factor_secret"
    t.text "two_factor_backup_codes"
    t.boolean "mfa_enabled"
    t.datetime "last_login_at"
    t.integer "login_count"
    t.integer "failed_login_attempts"
    t.datetime "locked_at"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.string "unconfirmed_email"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "alerts", "users"
  add_foreign_key "api_keys", "users"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "event_translations", "events"
  add_foreign_key "invitations", "roles"
  add_foreign_key "invitations", "teams"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "teams", "users"
  add_foreign_key "teams", "users", column: "owner_id"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "users", "roles"
  add_foreign_key "users", "teams"
end
