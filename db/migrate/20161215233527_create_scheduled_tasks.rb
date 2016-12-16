class CreateScheduledTasks < ActiveRecord::Migration
  def change
    create_table :scheduled_tasks do |t|
        t.string   "task_name"
        t.integer  "day_of_week"
        t.integer  "hour_of_day"
        t.datetime "last_successful_run"
        t.datetime "created_at"
        t.datetime "updated_at"
        t.string   "parameter_1"
        t.string   "parameter_1_type"
        t.string   "parameter_2"
        t.string   "parameter_2_type"
        t.string   "parameter_3"
        t.string   "parameter_3_type"
        t.datetime "last_attempt_date"
      t.timestamps null: false
    end
  end
end
