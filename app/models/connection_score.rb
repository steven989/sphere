class ConnectionScore < ActiveRecord::Base
    belongs_to :user
    belongs_to :connection
    before_save :backup, if: :should_backup?

    def histories
        ConnectionScoreHistory.where(user_id:self.user_id,connection_id:self.connection_id).order(created_at: :desc)
    end

    private

    def should_backup?
        if ConnectionScore.where(id:self.id).blank?
            return false
        else
            self.changed.each do |column_name|
                if ["date_of_score","score_quality","score_time"].include? column_name
                    return true
                end
            end
            return false
        end
        return false
    end

    def backup
        old_data = ConnectionScore.find(self.id)
        ConnectionScoreHistory.create(user_id:old_data.user_id,connection_id:old_data.connection_id,date_of_score:old_data.date_of_score,score_quality:old_data.score_quality,score_time:old_data.score_time)
    end    


end
