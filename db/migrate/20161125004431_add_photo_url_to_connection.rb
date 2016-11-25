class AddPhotoUrlToConnection < ActiveRecord::Migration
  def change
    add_column :connections, :photo_access_url, :string
  end
end
