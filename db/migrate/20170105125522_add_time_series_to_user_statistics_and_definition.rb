class AddTimeSeriesToUserStatisticsAndDefinition < ActiveRecord::Migration
  def change
    add_column :user_statistics, :year, :integer
    add_column :user_statistics, :month, :integer
    add_column :user_statistics, :week, :integer
    add_column :statistic_definitions, :timeframe, :string
    add_index :user_statistics, :year
    add_index :user_statistics, :month
    add_index :user_statistics, :week
  end
end
