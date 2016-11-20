class ChangeDatatypeOfFieldsThatAreCode < ActiveRecord::Migration
  def change
    change_column :statistic_definitions, :definition, :text
  end
end
