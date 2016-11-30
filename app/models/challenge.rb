class Challenge < ActiveRecord::Base
    has_many :user_challenges
    has_many :user_challenge_completeds
    has_many :current_users, through: :user_challenges, class_name: "User", foreign_key: "user_id", source: :user
    has_many :completed_users, through: :user_challenge_completeds, class_name: "User", foreign_key: "user_id", source: :user
    validates :name, presence: true
    validates :reward, presence: true

    def self.identify_challenges_for(current_user)
        number_of_challenges_to_display_to_user = SystemSetting.search("number_of_challenges_to_display_to_user").value_in_specified_type
        current_challenges = current_user.user_challenges
        number_of_challenges_already_displayed = current_challenges.length
        
        #1) Remove any challenges already completed and do not allow for repeats and already being shown
        list_of_challenges = Challenge.all.map {|challenge| challenge }
        list_of_completed_and_no_repeat_challenges = current_user.user_challenge_completeds.repeated_allowed(false)
        subset = list_of_challenges - list_of_completed_and_no_repeat_challenges - current_challenges
        subset.map {|challenge| {id:challenge.id, criteria:challenge.criteria,reward:challenge.reward}}
        #2) Find all the different statistics fields that will be required and save their values in a hash database isn't accessed for every comparison
        unique_list_of_user_statistics = subset.map{|challenge_data| challenge_data[:criteria].scan(/@[^@]+@/)}.flatten.uniq
        #3) Load these statistics
        current_user_relevant_statistics = unique_list_of_user_statistics.map{|stat| {stat.gsub("@",'') => current_user.user_statistics.find_statistic(stat.gsub("@",'')).take.value.to_f}}.reduce Hash.new, :merge
        #4) Filter the subset of challenges by their criteria and the loaded user statistics data
        set_that_user_qualifies_for = subset.select {|challenge| eval(Challenge.decode_criteria_into_executable_command(challenge['criteria'])) }
        #5) randomly pick gap number of challenges
        gap = [[number_of_challenges_to_display_to_user - number_of_challenges_already_displayed,0].max,set_that_user_qualifies_for.length].min
        result = []
        gap.times do
            result << set_that_user_qualifies_for[rand(set_that_user_qualifies_for.length)]
            set_that_user_qualifies_for = set_that_user_qualifies_for - result
        end
        result
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


    def self.update_challenge(delete,id,name,description,instructions,repeated_allowed,criteria,reward)
        if !id.blank?
            challengeObj = Challenge.find(id)
            if challengeObj
                if delete
                    challengeObj.destroy
                    status = true
                    message = "Challenge deleted"
                    elements = nil
                else

                    # evaluate the criteria to make sure it's actually good
                    evaluation_result = criteria == challengeObj.criteria ? true : User.find_users_matching_criteria(criteria)[:status]
                    if evaluation_result
                        challengeObj.assign_attributes(name:name,description:description,instructions:instructions,repeated_allowed:repeated_allowed,criteria:criteria,reward:reward)
                        if challengeObj.save
                            status = true
                            message = "Challenge successfully updated"
                            elements = nil
                        else
                            status = false
                            message = "Challenge could not be updated: #{challengeObj.errors.full_messages.join(', ')}"
                            elements = challengeObj.errors.messages.keys
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
                challengeObj = Challenge.new(name:name,description:description,instructions:instructions,repeated_allowed:repeated_allowed,criteria:criteria,reward:reward)
                if challengeObj.save
                    status = true
                    message = "Challenge successfully updated"
                    elements = nil
                else
                    status = false
                    message = "Challenge could not be updated: #{challengeObj.errors.full_messages.join(', ')}"
                    elements = challengeObj.errors.messages.keys
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
