class AddImportSourceAndIdToConnections < ActiveRecord::Migration
  def change
    add_column :connections, :source_provider, :string
    add_column :connections, :contact_id_at_provider, :string
  end
end
