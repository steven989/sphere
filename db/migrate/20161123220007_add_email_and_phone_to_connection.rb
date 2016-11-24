class AddEmailAndPhoneToConnection < ActiveRecord::Migration
  def change
    add_column :connections, :email, :string
    add_column :connections, :phone, :string
  end
end
