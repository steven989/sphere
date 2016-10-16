class User < ActiveRecord::Base
  authenticates_with_sorcery!
  has_many :connections
  has_many :activities
end
