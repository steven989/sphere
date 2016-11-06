class AddTypeToActivityDefinition < ActiveRecord::Migration
  def change
    add_column :activity_definitions, :activity_type, :string
  end
end
