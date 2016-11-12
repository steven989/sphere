class CreateConnectionScores < ActiveRecord::Migration
  def change
    create_table :connection_scores do |t|
        t.integer :user_id
        t.integer :connection_id
        t.date :date_of_score
        t.integer :score_quality
        t.integer :score_time

      t.timestamps null: false
    end
  end
end
