class Badge < ActiveRecord::Base
    has_many :user_badges
    has_many :users, through: :user_badges

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



end
