# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_22_075518) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "application_keys", primary_key: ["application_uid", "key_id"], force: :cascade do |t|
    t.string "application_uid", null: false
    t.uuid "key_id", null: false
    t.string "pem", null: false
    t.index ["application_uid"], name: "index_application_keys_on_application_uid"
  end

  create_table "email_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "topic_slug", null: false
    t.string "subscription_id"
    t.index ["user_id"], name: "index_email_subscriptions_on_user_id"
  end

  create_table "login_states", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "user_id", null: false
    t.string "redirect_path", null: false
    t.index ["user_id"], name: "index_login_states_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "contacts", default: [], array: true
    t.text "logo_uri"
    t.text "client_uri"
    t.text "policy_uri"
    t.index ["name"], name: "index_oauth_applications_on_name", unique: true
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_openid_requests", force: :cascade do |t|
    t.bigint "access_grant_id", null: false
    t.string "nonce", null: false
    t.index ["access_grant_id"], name: "index_oauth_openid_requests_on_access_grant_id"
  end

  create_table "registration_states", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "touched_at", null: false
    t.integer "state", null: false
    t.string "email", null: false
    t.string "previous_url"
    t.string "password"
    t.boolean "yes_to_emails"
    t.jsonb "jwt_payload"
    t.string "phone"
    t.string "phone_code"
    t.datetime "phone_code_generated_at"
    t.integer "mfa_attempts"
    t.boolean "cookie_consent"
    t.boolean "feedback_consent"
  end

  create_table "security_activities", force: :cascade do |t|
    t.integer "event_type", null: false
    t.bigint "user_id", null: false
    t.string "ip_address", null: false
    t.bigint "oauth_application_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["oauth_application_id"], name: "index_security_activities_on_oauth_application_id"
    t.index ["user_id"], name: "index_security_activities_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "phone"
    t.string "phone_code"
    t.datetime "phone_code_generated_at"
    t.integer "mfa_attempts"
    t.datetime "last_mfa_success"
    t.string "unconfirmed_phone"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "email_subscriptions", "users"
  add_foreign_key "login_states", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "oauth_openid_requests", "oauth_access_grants", column: "access_grant_id", on_delete: :cascade
  add_foreign_key "security_activities", "oauth_applications"
  add_foreign_key "security_activities", "users"
end
