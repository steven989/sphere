class AddUserStatsType < ActiveRecord::Migration
  def change
    add_column :user_statistics, :data_type, :string
    change_column :user_statistics, :value, :string
  end
end
