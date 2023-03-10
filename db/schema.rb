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

ActiveRecord::Schema[7.0].define(version: 2023_03_10_050504) do
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

  create_table "announcements", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chat_users", force: :cascade do |t|
    t.bigint "chat_id"
    t.bigint "user_id"
    t.string "title"
    t.text "description"
    t.integer "status", default: 0
    t.string "icon"
    t.integer "role", default: 0
    t.index ["chat_id"], name: "index_chat_users_on_chat_id"
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
    t.index ["chat_id"], name: "index_connect_codes_on_chat_id"
    t.index ["status"], name: "index_connect_codes_on_status"
    t.index ["user_id"], name: "index_connect_codes_on_user_id"
  end

  create_table "filters", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "tag_id"
    t.string "group", default: "default", null: false
    t.string "filter_type", limit: 25, null: false
    t.integer "priority", default: 0, null: false
    t.index ["tag_id"], name: "index_filters_on_tag_id"
    t.index ["user_id", "tag_id", "group"], name: "index_filters_on_user_id_and_tag_id_and_group", unique: true
    t.index ["user_id"], name: "index_filters_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id"
    t.bigint "user_id"
    t.text "content", null: false
    t.boolean "ooc", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "icon"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "object_tags", force: :cascade do |t|
    t.bigint "tag_id"
    t.string "object_type"
    t.bigint "object_id"
    t.index ["object_type", "object_id", "tag_id"], name: "index_object_tags_on_object_type_and_object_id_and_tag_id", unique: true
    t.index ["tag_id"], name: "index_object_tags_on_tag_id"
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
    t.index ["default_slots"], name: "index_prompts_on_default_slots"
    t.index ["user_id"], name: "index_prompts_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", limit: 254, null: false
    t.string "tag_type", limit: 25, null: false
    t.bigint "synonym_id"
    t.string "ancestry"
    t.string "polarity", limit: 25
    t.boolean "enabled", default: true, null: false
    t.index ["ancestry"], name: "index_tags_on_ancestry", opclass: :text_pattern_ops
    t.index ["name", "tag_type", "polarity"], name: "index_tags_on_name_and_tag_type_and_polarity", unique: true
    t.index ["synonym_id"], name: "index_tags_on_synonym_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.string "item_type"
    t.bigint "item_id"
    t.index ["item_type", "item_id"], name: "index_tickets_on_item"
    t.index ["user_id"], name: "index_tickets_on_user_id"
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
    t.datetime "unban_at", precision: nil
    t.string "ban_reason"
    t.datetime "delete_at", precision: nil
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chats", "prompts"
  add_foreign_key "connect_codes", "chats"
  add_foreign_key "connect_codes", "users"
  add_foreign_key "filters", "tags"
  add_foreign_key "filters", "users"
  add_foreign_key "object_tags", "tags"
  add_foreign_key "tags", "tags", column: "synonym_id"
  add_foreign_key "tickets", "users"
end
