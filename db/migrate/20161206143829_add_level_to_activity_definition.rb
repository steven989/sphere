class AddLevelToActivityDefinition < ActiveRecord::Migration
  def change
    add_column :activity_definitions, :specificity_level, :integer
  end
end
