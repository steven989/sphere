class AddSomeColumnsToChallenge < ActiveRecord::Migration
  def change
    add_column :user_challenges, :date_shown_to_user, :date
    add_column :user_challenges, :date_started, :date
    add_column :user_challenge_completeds, :date_started, :date
    add_column :user_challenge_completeds, :reward, :integer
    add_column :challenges, :days_to_complete, :integer, default: 7
    remove_column :challenges, :reward
    add_column :challenges, :reward, :integer
    add_column :user_challenges, :status, :string, default: "presented"
  end
end
