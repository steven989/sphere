class CreateLevelHistories < ActiveRecord::Migration
  def change
    create_table :level_histories do |t|
        t.integer :level
        t.date :date_achieved

      t.timestamps null: false
    end
  end
end
