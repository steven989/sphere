class AddToggleToChallengesToEnableRepeat < ActiveRecord::Migration
  def change
    add_column :challenges, :repeated_allowed, :boolean, default: true
    add_column :user_challenge_completeds, :repeated_allowed, :boolean
  end
end
