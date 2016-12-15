class AddIndicesToForeignKeys < ActiveRecord::Migration
  def change
    add_index :activities, :user_id
    add_index :activities, :connection_id
    add_index :authorizations, :user_id
    add_index :connection_notes, :user_id
    add_index :connection_notes, :connection_id
    add_index :connection_score_histories, :user_id
    add_index :connection_score_histories, :connection_id
    add_index :connection_scores, :user_id
    add_index :connection_scores, :connection_id    
    add_index :connections, :user_id
    add_index :notifications, :user_id
    add_index :notifications, [:notifiable_id,:notifiable_type]
    add_index :plans, :user_id
    add_index :plans, :connection_id
    add_index :tags, :user_id
    add_index :user_challenge_completeds, :user_id
    add_index :user_challenge_completeds, :challenge_id
    add_index :user_challenges, :user_id
    add_index :user_challenges, :challenge_id
    add_index :user_settings, :user_id
    add_index :user_statistics, :user_id
    add_index :user_statistics, :statistic_definition_id
    add_index :user_statistics, :name
  end
end
