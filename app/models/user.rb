class User < ActiveRecord::Base
  authenticates_with_sorcery!
  has_many :connections
  has_many :activities  

  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }

  validates :email, uniqueness: true
end
