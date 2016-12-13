class SomethingElseToAddToUserChallenges < ActiveRecord::Migration
  def change
    add_column :user_challenges, :date_to_be_completed, :date
    add_column :user_challenge_completeds, :date_to_be_completed, :date
  end
end
