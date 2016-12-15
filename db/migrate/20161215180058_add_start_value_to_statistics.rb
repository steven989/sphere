class AddStartValueToStatistics < ActiveRecord::Migration
  def change
    add_column :statistic_definitions, :start_value_type, :string
    add_column :statistic_definitions, :start_value, :string
  end
end
