# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170122172652) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.integer  "user_id",                null: false
    t.integer  "connection_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "activity_type"
    t.string   "activity"
    t.date     "date"
    t.text     "activity_description"
    t.integer  "activity_definition_id"
    t.integer  "initiator"
    t.text     "notes"
  end

  add_index "activities", ["connection_id"], name: "index_activities_on_connection_id", using: :btree
  add_index "activities", ["user_id"], name: "index_activities_on_user_id", using: :btree

  create_table "activity_definitions", force: :cascade do |t|
    t.string   "activity"
    t.integer  "point_shared_experience_one_to_one"
    t.integer  "point_shared_experience_group_private"
    t.integer  "point_shared_experience_group_public"
    t.integer  "point_provide_help"
    t.integer  "point_receive_help"
    t.integer  "point_provide_gift"
    t.integer  "point_receive_gift"
    t.integer  "point_shared_outcome"
    t.integer  "point_shared_challenge"
    t.integer  "point_communication_digital"
    t.integer  "point_communication_in_person"
    t.integer  "point_shared_interest"
    t.integer  "point_intimacy",                        null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "specificity_level"
  end

  create_table "app_usages", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "action"
    t.string   "additional_info"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "app_usages", ["user_id"], name: "index_app_usages_on_user_id", using: :btree

  create_table "authorizations", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.text     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "scope"
    t.boolean  "login"
  end

  add_index "authorizations", ["user_id"], name: "index_authorizations_on_user_id", using: :btree

  create_table "badges", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.string   "criteria"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "graphic"
  end

  create_table "challenges", force: :cascade do |t|
    t.string   "name"
    t.text     "instructions"
    t.text     "description"
    t.string   "criteria"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "repeated_allowed", default: true
    t.string   "graphic"
    t.integer  "days_to_complete", default: 7
    t.integer  "reward"
  end

  create_table "connection_notes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "connection_id"
    t.text     "notes"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "connection_notes", ["connection_id"], name: "index_connection_notes_on_connection_id", using: :btree
  add_index "connection_notes", ["user_id"], name: "index_connection_notes_on_user_id", using: :btree

  create_table "connection_score_histories", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "connection_id"
    t.date     "date_of_score"
    t.integer  "score_quality"
    t.integer  "score_time"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "connection_score_histories", ["connection_id"], name: "index_connection_score_histories_on_connection_id", using: :btree
  add_index "connection_score_histories", ["user_id"], name: "index_connection_score_histories_on_user_id", using: :btree

  create_table "connection_scores", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "connection_id"
    t.date     "date_of_score"
    t.integer  "score_quality"
    t.integer  "score_time"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "connection_scores", ["connection_id"], name: "index_connection_scores_on_connection_id", using: :btree
  add_index "connection_scores", ["user_id"], name: "index_connection_scores_on_user_id", using: :btree

  create_table "connections", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.integer  "target_contact_interval_in_days"
    t.boolean  "active"
    t.string   "email"
    t.string   "phone"
    t.string   "photo"
    t.string   "photo_access_url"
    t.string   "additional_emails",               default: "[]"
    t.string   "additional_phones",               default: "[]"
    t.string   "source_provider"
    t.string   "contact_id_at_provider"
    t.string   "frequency_word"
    t.text     "notes"
    t.date     "date_inactive"
    t.integer  "times_degraded"
  end

  add_index "connections", ["user_id"], name: "index_connections_on_user_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "external_notifications", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "notification_type"
    t.string   "notification_medium"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "level_histories", force: :cascade do |t|
    t.integer  "level"
    t.date     "date_achieved"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "levels", force: :cascade do |t|
    t.integer  "level"
    t.string   "criteria"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "graphic"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "notification_type"
    t.date     "notification_date"
    t.date     "expiry_date"
    t.string   "data_type"
    t.string   "value"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "priority"
    t.integer  "notifiable_id"
    t.string   "notifiable_type"
    t.boolean  "one_time_display",  default: false
  end

  add_index "notifications", ["notifiable_id", "notifiable_type"], name: "index_notifications_on_notifiable_id_and_notifiable_type", using: :btree
  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree

  create_table "penalties", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "statistic_definition_id"
    t.date     "penalty_date"
    t.string   "penalty_statistic"
    t.string   "penalty_type"
    t.float    "amount"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "connection_id"
  end

  add_index "penalties", ["connection_id"], name: "index_penalties_on_connection_id", using: :btree
  add_index "penalties", ["statistic_definition_id"], name: "index_penalties_on_statistic_definition_id", using: :btree
  add_index "penalties", ["user_id"], name: "index_penalties_on_user_id", using: :btree

  create_table "plans", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "connection_id"
    t.date     "date"
    t.string   "timezone"
    t.string   "name"
    t.string   "location"
    t.string   "status"
    t.string   "calendar_id"
    t.string   "calendar_event_id"
    t.boolean  "invite_sent"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.datetime "date_time"
    t.float    "length"
    t.string   "edit_time_url"
    t.text     "details"
    t.datetime "end_date_time"
    t.boolean  "put_on_calendar",   default: false
  end

  add_index "plans", ["connection_id"], name: "index_plans_on_connection_id", using: :btree
  add_index "plans", ["user_id"], name: "index_plans_on_user_id", using: :btree

  create_table "scheduled_tasks", force: :cascade do |t|
    t.string   "task_name"
    t.integer  "day_of_week"
    t.integer  "hour_of_day"
    t.datetime "last_successful_run"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "parameter_1"
    t.string   "parameter_1_type"
    t.string   "parameter_2"
    t.string   "parameter_2_type"
    t.string   "parameter_3"
    t.string   "parameter_3_type"
    t.datetime "last_attempt_date"
  end

  create_table "sent_emails", force: :cascade do |t|
    t.integer  "user_id"
    t.date     "sent_date"
    t.string   "allowable_frequency"
    t.string   "source"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "sent_emails", ["user_id"], name: "index_sent_emails_on_user_id", using: :btree

  create_table "sign_up_codes", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "code"
    t.integer  "quantity"
    t.integer  "quantity_used"
    t.string   "description"
    t.date     "valid_after"
    t.date     "valid_before"
    t.string   "code_type"
    t.boolean  "active"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "sign_up_codes", ["code"], name: "index_sign_up_codes_on_code", unique: true, using: :btree
  add_index "sign_up_codes", ["user_id"], name: "index_sign_up_codes_on_user_id", using: :btree

  create_table "statistic_definitions", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.text     "definition"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "operation_type"
    t.string   "operation_trigger"
    t.integer  "priority",          default: 1
    t.string   "start_value_type"
    t.string   "start_value"
    t.string   "timeframe"
  end

  create_table "system_settings", force: :cascade do |t|
    t.string   "name"
    t.string   "data_type"
    t.string   "value"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "description"
  end

  create_table "tags", force: :cascade do |t|
    t.string   "tag"
    t.integer  "user_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "tags", ["taggable_type", "taggable_id"], name: "index_tags_on_taggable_type_and_taggable_id", using: :btree
  add_index "tags", ["user_id"], name: "index_tags_on_user_id", using: :btree

  create_table "user_badges", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "badge_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_challenge_completeds", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "challenge_id"
    t.date     "date_shown_to_user"
    t.date     "date_completed"
    t.string   "method_of_completion"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.boolean  "repeated_allowed"
    t.date     "date_started"
    t.integer  "reward"
    t.date     "date_to_be_completed"
  end

  add_index "user_challenge_completeds", ["challenge_id"], name: "index_user_challenge_completeds_on_challenge_id", using: :btree
  add_index "user_challenge_completeds", ["user_id"], name: "index_user_challenge_completeds_on_user_id", using: :btree

  create_table "user_challenges", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "challenge_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.date     "date_shown_to_user"
    t.date     "date_started"
    t.string   "status",               default: "presented"
    t.date     "date_to_be_completed"
  end

  add_index "user_challenges", ["challenge_id"], name: "index_user_challenges_on_challenge_id", using: :btree
  add_index "user_challenges", ["user_id"], name: "index_user_challenges_on_user_id", using: :btree

  create_table "user_reminders", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "connection_id"
    t.string   "reminder"
    t.string   "status"
    t.date     "due_date"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "user_reminders", ["connection_id"], name: "index_user_reminders_on_connection_id", using: :btree
  add_index "user_reminders", ["user_id"], name: "index_user_reminders_on_user_id", using: :btree

  create_table "user_settings", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "value",      default: "{}"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "user_settings", ["user_id"], name: "index_user_settings_on_user_id", using: :btree

  create_table "user_statistics", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "statistic_definition_id"
    t.string   "name"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "data_type"
    t.float    "value"
    t.integer  "year"
    t.integer  "month"
    t.integer  "week"
  end

  add_index "user_statistics", ["month"], name: "index_user_statistics_on_month", using: :btree
  add_index "user_statistics", ["name"], name: "index_user_statistics_on_name", using: :btree
  add_index "user_statistics", ["statistic_definition_id"], name: "index_user_statistics_on_statistic_definition_id", using: :btree
  add_index "user_statistics", ["user_id"], name: "index_user_statistics_on_user_id", using: :btree
  add_index "user_statistics", ["week"], name: "index_user_statistics_on_week", using: :btree
  add_index "user_statistics", ["year"], name: "index_user_statistics_on_year", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                           null: false
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "photo"
    t.string   "photo_access_url"
    t.string   "phone"
    t.string   "timezone"
    t.string   "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.boolean  "tester"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", using: :btree

end
