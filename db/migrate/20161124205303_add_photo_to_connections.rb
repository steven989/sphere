class AddPhotoToConnections < ActiveRecord::Migration
  def change
    add_column :connections, :photo, :string
  end
end
