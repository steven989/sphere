class AddMoreInfoToAuthorization < ActiveRecord::Migration
  def change
    add_column :authorizations, :login, :boolean
  end
end
