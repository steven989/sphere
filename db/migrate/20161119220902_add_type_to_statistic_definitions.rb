class AddTypeToStatisticDefinitions < ActiveRecord::Migration
  def change
    add_column :statistic_definitions, :operation_type, :string
    add_column :statistic_definitions, :operation_trigger, :string
  end
end
