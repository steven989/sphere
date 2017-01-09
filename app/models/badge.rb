class Badge < ActiveRecord::Base
    has_many :user_badges, :dependent => :destroy
    has_many :users, through: :user_badges
    validates :name, presence: true
    mount_uploader :graphic, GraphicUploader

    def self.identify_badges_for(current_user)
        current_badges = current_user.user_badges
        
        #1) Remove any badges already shown to user
        list_of_badges = Badge.all.map {|badge| badge }
        subset = list_of_badges - current_user.badges
        subset.map {|badge| {id:badge.id, criteria:badge.criteria}}
        #2) Find all the different statistics fields that will be required and save their values in a hash database isn't accessed for every comparison
        unique_list_of_user_statistics = subset.map{|badge_data| badge_data[:criteria].scan(/@[^@]+@/)}.flatten.uniq
        #3) Load these statistics
        current_user_relevant_statistics = unique_list_of_user_statistics.map{|stat| {stat.gsub("@",'') => current_user.user_statistics.find_statistic(stat.gsub("@",'')).take.value.to_f}}.reduce Hash.new, :merge
        #4) Filter the subset of badges by their criteria and the loaded user statistics data
        new_set_that_user_qualifies_for = subset.select {|badge| eval(Badge.decode_criteria_into_executable_command(badge['criteria'])) }
        new_set_that_user_qualifies_for
    end

    def self.decode_criteria_into_executable_command(criteria)
        stat_specified = criteria.scan(/@[^@]+@/).uniq
        operators_specified = criteria.scan(/#[^#]+#/).uniq
        operator_dictionary = {"and" => "&&", "or" => "||"}
        stat_with_replacement = stat_specified.map {|stat| {stat => "current_user_relevant_statistics[#{stat.gsub('@','"')}]"} }
        operator_with_replacement = operators_specified.map {|operator| {operator => "#{operator_dictionary[operator.gsub('#','').downcase]}"} }
        stat_with_replacement.each {|replacement| criteria.gsub!(replacement.keys[0],replacement.values[0]) }
        operator_with_replacement.each {|replacement| criteria.gsub!(replacement.keys[0],replacement.values[0]) }
        criteria
    end


    def self.update_badge(delete,id,name,description,criteria,graphic)
        if !id.blank?
            badgeObj = Badge.find(id)
            if badgeObj
                if delete
                    if badgeObj.user_badges.length == 0
                        badgeObj.destroy
                        status = true
                        message = "Badge deleted"
                        elements = nil
                    else
                        status = false
                        message = "#{badgeObj.name} cannot be deleted: already earned by a users"
                        elements = nil
                    end
                else
                    # evaluate the criteria to make sure it's actually good
                    evaluation_result = criteria == badgeObj.criteria ? true : User.find_users_matching_criteria(criteria)[:status]
                    if evaluation_result
                        if !((graphic == "undefined") || (graphic == "null") || graphic.blank?)
                            badgeObj.remove_graphic!
                            badgeObj.save
                            badgeObj.graphic = graphic
                        end 
                        badgeObj.assign_attributes(name:name,description:description,criteria:criteria)
                        begin
                            savedObj = badgeObj.save
                        rescue => error
                            status = false
                            message = "#{badgeObj.name} could not be updated: #{error.message}"
                            elements = nil                            
                        else
                            if savedObj
                                status = true
                                message = "Badge successfully updated"
                                elements = nil
                            else
                                status = false
                                message = "#{badgeObj.name} could not be updated: #{badgeObj.errors.full_messages.join(', ')}"
                                elements = badgeObj.errors.messages.keys
                            end
                        end
                    else
                        status = false
                        message = "Incorrect criteria syntax"
                        elements = [:criteria]
                    end
                end


            else
                status = true
                message = "Did not find ID. No action performed"
                elements = nil
            end 
        else
            # evaluate the criteria to make sure it's actually good
            evaluation_result = User.find_users_matching_criteria(criteria)[:status]
            if evaluation_result
                badgeObj = Badge.new(name:name,description:description,criteria:criteria)
                if !((graphic == "undefined") || (graphic == "null") || graphic.blank?)
                    badgeObj.remove_graphic!
                    badgeObj.save
                    badgeObj.graphic = graphic
                end 
                if badgeObj.save
                    status = true
                    message = "Badge successfully updated"
                    elements = nil
                else
                    status = false
                    message = "Badge could not be updated: #{badgeObj.errors.full_messages.join(', ')}"
                    elements = badgeObj.errors.messages.keys
                end
            else
                status = false
                message = "Incorrect criteria syntax"
                elements = [:criteria]
            end
        end
        {status:status,message:message,elements:elements}
    end


end
