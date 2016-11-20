class AddExecutionPriorityToStatisticDefinition < ActiveRecord::Migration
  def change
    add_column :statistic_definitions, :priority, :integer, default: 1
  end
end
