class CreateAppUsages < ActiveRecord::Migration
  def change
    create_table :app_usages do |t|
        t.integer :user_id
        t.string :action
        t.string :additional_info
      t.timestamps null: false
    end
    add_index :app_usages, :user_id
  end
end
