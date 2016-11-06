class CreateActivityDefinitions < ActiveRecord::Migration
  def change
    create_table :activity_definitions do |t|
        t.string :activity
        t.integer :point_shared_experience_one_to_one
        t.integer :point_shared_experience_group_private
        t.integer :point_shared_experience_group_public
        t.integer :point_provide_help
        t.integer :point_receive_help
        t.integer :point_provide_gift
        t.integer :point_receive_gift
        t.integer :point_shared_outcome
        t.integer :point_shared_challenge
        t.integer :point_communication_digital
        t.integer :point_communication_in_person
        t.integer :point_shared_interest
        t.integer :point_intimacy

      t.timestamps null: false
    end
  end
end
