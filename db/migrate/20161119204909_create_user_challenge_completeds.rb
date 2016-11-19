class CreateUserChallengeCompleteds < ActiveRecord::Migration
  def change
    create_table :user_challenge_completeds do |t|
        t.integer :user_id
        t.integer :challenge_id
        t.date :date_shown_to_user
        t.date :date_completed
        t.string :method_of_completion

      t.timestamps null: false
    end
  end
end
