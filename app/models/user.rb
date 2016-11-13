class User < ActiveRecord::Base
  authenticates_with_sorcery!
  has_many :connections
  has_many :activities  
  has_many :connection_scores
  has_many :connection_score_histories

  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }

  validates :email, uniqueness: true

  def calculate_quality_score_for_all_connections
 
      self.connections.each do |connection|
        connection.update_score
      end
      
  end

end
