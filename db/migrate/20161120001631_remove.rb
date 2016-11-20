class Remove < ActiveRecord::Migration
  def change
    remove_column :levels, :user_id
  end
end
