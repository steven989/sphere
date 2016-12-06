class ActivityDefinition < ActiveRecord::Base
    has_many :activities
    scope :level, -> (level) { where(specificity_level:level) }
end
