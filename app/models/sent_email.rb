class SentEmail < ActiveRecord::Base

    def self.remove_all_useless_records
        SentEmail.where("(allowable_frequency ilike 'daily' and sent_date < ?) or (allowable_frequency ilike 'weekly' and sent_date < ?)",Date.today - 2.days,Date.today - 15.days).destroy_all
    end
end
