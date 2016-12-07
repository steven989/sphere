class RevertUserStatisticsValueBackToFloat < ActiveRecord::Migration
  def change
    remove_column :user_statistics, :value
    add_column :user_statistics, :value, :float
  end
end
