class Level < ActiveRecord::Base
    validates :level, presence: true
    validates :level, uniqueness: true
    validates :criteria, uniqueness: true
    mount_uploader :graphic, GraphicUploader

    def self.find_level_for(current_user)
        sorted_array_of_leveling_criteria = Level.all.order(level: :asc).map {|level| {level:level.level, criteria:level.criteria}}
        current_recorded_level = current_user.user_statistics.find_statistic("level")
        if current_recorded_level
            [Level.find_level(current_user,sorted_array_of_leveling_criteria),current_recorded_level.take.value].max #if there's already a level, do not let the new returned level be below the existing one (could happen due to definition change)
        else
            Level.find_level(current_user,sorted_array_of_leveling_criteria)
        end
        
    end

    def self.return_level_xps(levels=[])
        if levels.length != 0
            levels_object = Level.where(level:levels)
            levels_object.inject({}){|result,level| result[level.level] = level.criteria.match(/[0-9]+/)[0].to_i;result}
        else
            nil
        end
    end

    def self.update_level(delete,id,level,criteria)
        if !id.blank?
            levelObj = Level.find(id)
            if levelObj
                if delete
                    levelObj.destroy
                    status = true
                    message = "Level deleted"
                    elements = nil
                else

                    # evaluate the criteria to make sure it's actually good
                    evaluation_result = criteria == levelObj.criteria ? true : User.find_users_matching_criteria(criteria)[:status]
                    if evaluation_result
                        levelObj.assign_attributes(level:level,criteria:criteria)
                        if levelObj.save
                            status = true
                            message = "Level successfully updated"
                            elements = nil
                        else
                            status = false
                            message = "Level could not be updated: #{levelObj.errors.full_messages.join(', ')}"
                            elements = levelObj.errors.messages.keys
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
                levelObj = Level.new(level:level,criteria:criteria)
                if levelObj.save
                    status = true
                    message = "Level successfully updated"
                    elements = nil
                else
                    status = false
                    message = "Level could not be updated: #{levelObj.errors.full_messages.join(', ')}"
                    elements = levelObj.errors.messages.keys
                end
            else
                status = false
                message = "Incorrect criteria syntax"
                elements = [:criteria]
            end
        end
        {status:status,message:message,elements:elements}
    end

    private

    # use a recursive algorithm to find the level. Start with a mid point, if both this element and the element to its right is true, then go to the right half. If this element is false (which means the right element must be false because leveling is in one direction from left to right), go to the left half. If this element is true and the next one is false, or this is the last element, then return the level
    def self.find_level(current_user,sorted_array_of_leveling_criteria,position=sorted_array_of_leveling_criteria.length/2,left_boudary=0,right_boundary=sorted_array_of_leveling_criteria.length-1)
        length_of_levels_array = sorted_array_of_leveling_criteria.length
        current_position_result = eval(Level.decode_criteria_into_executable_command(sorted_array_of_leveling_criteria[position][:criteria]))
        if (current_position_result && (position == length_of_levels_array-1)) || (current_position_result && !eval(Level.decode_criteria_into_executable_command(sorted_array_of_leveling_criteria[position+1][:criteria])))
            sorted_array_of_leveling_criteria[position][:level]
        else
            new_position = !current_position_result ? (left_boudary + position)/2 : (position + right_boundary + 1)/2
            new_left_boundary = !current_position_result ? left_boudary : position
            new_right_boundary = !current_position_result ? position : right_boundary
            self.find_level(current_user,sorted_array_of_leveling_criteria,new_position,new_left_boundary,new_right_boundary)
        end
    end

    def self.decode_criteria_into_executable_command(criteria)
        stat_specified = criteria.scan(/@[^@]+@/).uniq
        operators_specified = criteria.scan(/#[^#]+#/).uniq
        operator_dictionary = {"and" => "&&", "or" => "||"}
        stat_with_replacement = stat_specified.map {|stat| {stat => "current_user.user_statistics.find_statistic(#{stat.gsub('@','"')}).take.value.to_f"} }
        operator_with_replacement = operators_specified.map {|operator| {operator => "#{operator_dictionary[operator.gsub('#','').downcase]}"} }
        stat_with_replacement.each {|replacement| criteria.gsub!(replacement.keys[0],replacement.values[0]) }
        operator_with_replacement.each {|replacement| criteria.gsub!(replacement.keys[0],replacement.values[0]) }
        criteria
    end


end
