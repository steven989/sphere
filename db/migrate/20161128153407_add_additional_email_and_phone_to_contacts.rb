class AddAdditionalEmailAndPhoneToContacts < ActiveRecord::Migration
  def change
    add_column :connections, :additional_emails, :string, default: "[]"
    add_column :connections, :additional_phones, :string, default: "[]"
  end
end
