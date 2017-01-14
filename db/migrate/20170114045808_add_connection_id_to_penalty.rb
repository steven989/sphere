class AddConnectionIdToPenalty < ActiveRecord::Migration
  def change
    add_column :penalties, :connection_id, :integer
    add_column :connections, :times_degraded, :integer

    add_index :penalties, :connection_id
  end
end
