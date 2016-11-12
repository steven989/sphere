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
        quality_score = connection.calculate_quality_score
        log_score(connection,quality_score)
      end
      
  end

  def log_score(connection,quality_score)
      connection_score = ConnectionScore.where(user_id:self.id,connection_id:connection.id).take
      if connection_score.blank?
        ConnectionScore.create(user_id:self.id,connection_id:connection.id,date_of_score:Date.today,score_quality:quality_score)
      else
        connection_score.update_attributes(date_of_score:Date.today,score_quality:quality_score)
      end
  end


end
