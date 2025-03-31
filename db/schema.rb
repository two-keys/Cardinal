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

ActiveRecord::Schema[7.2].define(version: 2025_03_30_204554) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ads", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "variant", default: 0, null: false
    t.string "url"
    t.integer "impressions", default: 0, null: false
    t.integer "clicks", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "approved_url"
    t.boolean "pending_approval", default: true, null: false
    t.index ["user_id"], name: "index_ads_on_user_id"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "alerts", force: :cascade do |t|
    t.string "title", null: false
    t.string "find", null: false
    t.boolean "regex", default: false
    t.string "replacement"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "announcements", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "push", default: false, null: false
  end

  create_table "characters", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "pseudonym_id"
    t.text "color", default: "#000000", null: false
    t.index ["pseudonym_id"], name: "index_characters_on_pseudonym_id"
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "chat_users", force: :cascade do |t|
    t.bigint "chat_id"
    t.bigint "user_id"
    t.string "title"
    t.text "description"
    t.integer "status", default: 0
    t.string "icon"
    t.integer "role", default: 0
    t.bigint "pseudonym_id"
    t.text "color", default: "#000000", null: false
    t.index ["chat_id"], name: "index_chat_users_on_chat_id"
    t.index ["pseudonym_id"], name: "index_chat_users_on_pseudonym_id"
    t.index ["role"], name: "index_chat_users_on_role"
    t.index ["user_id", "chat_id"], name: "index_chat_users_on_user_id_and_chat_id", unique: true
    t.index ["user_id"], name: "index_chat_users_on_user_id"
  end

  create_table "chats", force: :cascade do |t|
    t.uuid "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "prompt_id"
    t.index ["prompt_id"], name: "index_chats_on_prompt_id"
    t.index ["uuid"], name: "index_chats_on_uuid"
  end

  create_table "connect_codes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "chat_id"
    t.string "code"
    t.integer "remaining_uses", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.string "title"
    t.text "description"
    t.index ["chat_id"], name: "index_connect_codes_on_chat_id"
    t.index ["status"], name: "index_connect_codes_on_status"
    t.index ["user_id"], name: "index_connect_codes_on_user_id"
  end

  create_table "entitlements", force: :cascade do |t|
    t.string "object_type"
    t.bigint "object_id"
    t.string "flag"
    t.string "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["flag", "data"], name: "index_entitlements_on_flag_and_data"
    t.index ["flag"], name: "index_entitlements_on_flag"
    t.index ["object_id", "object_type", "flag", "data"], name: "idx_on_object_id_object_type_flag_data_01f8cbf101"
    t.index ["object_id", "object_type"], name: "index_entitlements_on_object_id_and_object_type"
    t.index ["object_id"], name: "index_entitlements_on_object_id"
    t.index ["object_type", "object_id"], name: "index_entitlements_on_object"
    t.index ["object_type"], name: "index_entitlements_on_object_type"
    t.index ["title"], name: "index_entitlements_on_title"
  end

  create_table "filters", force: :cascade do |t|
    t.bigint "user_id"
    t.string "group", default: "default", null: false
    t.string "filter_type", limit: 25, null: false
    t.integer "priority", default: 0, null: false
    t.string "target_type"
    t.bigint "target_id"
    t.index ["target_type", "target_id", "group", "user_id"], name: "idx_on_target_type_target_id_group_user_id_394635f237", unique: true
    t.index ["target_type", "target_id"], name: "index_filters_on_target"
    t.index ["user_id"], name: "index_filters_on_user_id"
  end

  create_table "ip_bans", force: :cascade do |t|
    t.string "title"
    t.text "context"
    t.inet "addr", null: false
    t.datetime "expires_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["addr"], name: "index_ip_bans_on_addr", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id"
    t.bigint "user_id"
    t.text "content", null: false
    t.boolean "ooc", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "icon"
    t.text "color", default: "#000000", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "object_characters", force: :cascade do |t|
    t.bigint "character_id"
    t.string "object_type"
    t.bigint "object_id"
    t.index ["character_id"], name: "index_object_characters_on_character_id"
    t.index ["object_type", "object_id", "character_id"], name: "index_object_characters_with_id", unique: true
    t.index ["object_type", "object_id"], name: "index_object_characters_on_object"
  end

  create_table "object_tags", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "object_type"
    t.bigint "object_id"
    t.index ["object_type", "object_id", "tag_id"], name: "index_object_tags_on_object_type_and_object_id_and_tag_id", unique: true
    t.index ["tag_id"], name: "index_object_tags_on_tag_id"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.bigint "user_id"
    t.bigint "chat_id"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_pg_search_documents_on_chat_id"
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
    t.index ["user_id"], name: "index_pg_search_documents_on_user_id"
  end

  create_table "prompts", force: :cascade do |t|
    t.bigint "user_id"
    t.text "starter"
    t.text "ooc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "bumped_at", null: false
    t.integer "default_slots", default: 2, null: false
    t.boolean "managed", default: false, null: false
    t.bigint "pseudonym_id"
    t.text "color", default: "#000000", null: false
    t.index ["default_slots"], name: "index_prompts_on_default_slots"
    t.index ["managed"], name: "index_prompts_on_managed"
    t.index ["pseudonym_id"], name: "index_prompts_on_pseudonym_id"
    t.index ["user_id"], name: "index_prompts_on_user_id"
  end

  create_table "pseudonyms", force: :cascade do |t|
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pseudonyms_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "endpoint"
    t.string "p256dh_key"
    t.string "auth_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.boolean "handled", default: false
    t.integer "rules", default: [], null: false, array: true
    t.bigint "reporter_id", null: false
    t.bigint "reportee_id", null: false
    t.string "reportable_type", null: false
    t.bigint "reportable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "handled_by_id"
    t.index ["handled_by_id"], name: "index_reports_on_handled_by_id"
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable"
    t.index ["reportee_id"], name: "index_reports_on_reportee_id"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
  end

  create_table "rollups", force: :cascade do |t|
    t.string "name", null: false
    t.string "interval", null: false
    t.datetime "time", null: false
    t.jsonb "dimensions", default: {}, null: false
    t.float "value"
    t.index ["name", "interval", "time", "dimensions"], name: "index_rollups_on_name_and_interval_and_time_and_dimensions", unique: true
  end

  create_table "snapshot_items", force: :cascade do |t|
    t.bigint "snapshot_id", null: false
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.json "object", null: false
    t.datetime "created_at", null: false
    t.string "child_group_name"
    t.index ["item_type", "item_id"], name: "index_snapshot_items_on_item"
    t.index ["snapshot_id", "item_id", "item_type"], name: "index_snapshot_items_on_snapshot_id_and_item_id_and_item_type", unique: true
    t.index ["snapshot_id"], name: "index_snapshot_items_on_snapshot_id"
  end

  create_table "snapshots", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "user_type"
    t.bigint "user_id"
    t.string "identifier"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.index ["identifier", "item_id", "item_type"], name: "index_snapshots_on_identifier_and_item_id_and_item_type", unique: true
    t.index ["identifier"], name: "index_snapshots_on_identifier"
    t.index ["item_type", "item_id"], name: "index_snapshots_on_item"
    t.index ["user_type", "user_id"], name: "index_snapshots_on_user"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", limit: 254, null: false
    t.string "tag_type", limit: 25, null: false
    t.bigint "synonym_id"
    t.string "ancestry"
    t.string "polarity", limit: 25
    t.boolean "enabled", default: true, null: false
    t.string "lower", limit: 254, null: false
    t.index ["ancestry"], name: "index_tags_on_ancestry", opclass: :text_pattern_ops
    t.index ["lower", "tag_type", "polarity"], name: "index_tags_on_lower_and_tag_type_and_polarity", unique: true
    t.index ["name", "tag_type", "polarity"], name: "index_tags_on_name_and_tag_type_and_polarity", unique: true
    t.index ["synonym_id"], name: "index_tags_on_synonym_id"
  end

  create_table "themes", force: :cascade do |t|
    t.string "title", null: false
    t.boolean "public", default: false, null: false
    t.boolean "system", default: false, null: false
    t.text "css", default: "", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["public"], name: "index_themes_on_public"
    t.index ["system"], name: "index_themes_on_system"
    t.index ["user_id"], name: "index_themes_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.string "item_type"
    t.bigint "item_id"
    t.index ["item_type", "item_id"], name: "index_tickets_on_item"
    t.index ["user_id"], name: "index_tickets_on_user_id"
  end

  create_table "user_entitlements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "entitlement_id", null: false
    t.datetime "expires_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entitlement_id"], name: "index_user_entitlements_on_entitlement_id"
    t.index ["user_id", "entitlement_id"], name: "index_user_entitlements_on_user_id_and_entitlement_id", unique: true
    t.index ["user_id"], name: "index_user_entitlements_on_user_id"
  end

  create_table "user_themes", force: :cascade do |t|
    t.boolean "enabled", default: false, null: false
    t.bigint "user_id", null: false
    t.bigint "theme_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority", default: 0
    t.index ["enabled"], name: "index_user_themes_on_enabled"
    t.index ["theme_id"], name: "index_user_themes_on_theme_id"
    t.index ["user_id"], name: "index_user_themes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: ""
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", default: "", null: false
    t.boolean "admin", default: false
    t.boolean "verified", default: false
    t.datetime "unban_at"
    t.string "ban_reason"
    t.datetime "delete_at"
    t.bigint "theme_id"
    t.boolean "push_announcements", default: true, null: false
    t.boolean "themes_enabled", default: false, null: false
    t.boolean "legacy", default: false, null: false
    t.string "time_zone", default: "UTC", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["theme_id"], name: "index_users_on_theme_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ads", "users"
  add_foreign_key "characters", "pseudonyms"
  add_foreign_key "characters", "users"
  add_foreign_key "chat_users", "pseudonyms"
  add_foreign_key "chats", "prompts"
  add_foreign_key "connect_codes", "chats"
  add_foreign_key "connect_codes", "users"
  add_foreign_key "filters", "users"
  add_foreign_key "object_characters", "characters"
  add_foreign_key "object_tags", "tags"
  add_foreign_key "prompts", "pseudonyms"
  add_foreign_key "pseudonyms", "users"
  add_foreign_key "reports", "users", column: "handled_by_id"
  add_foreign_key "reports", "users", column: "reportee_id"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "tags", "tags", column: "synonym_id"
  add_foreign_key "themes", "users"
  add_foreign_key "tickets", "users"
  add_foreign_key "user_entitlements", "entitlements"
  add_foreign_key "user_entitlements", "users"
  add_foreign_key "user_themes", "themes"
  add_foreign_key "user_themes", "users"
  add_foreign_key "users", "themes"
end
