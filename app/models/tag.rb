class Tag < ActiveRecord::Base
    belongs_to :taggable, polymorphic: true #Using polymorphic association here since in the future we may be tagging more than just connections
    belongs_to :user
end
