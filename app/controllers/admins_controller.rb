class AdminsController < ApplicationController

    def dashboard
        # View, create, edit levels
        
        # View, create, edit challenges
        # View, create, edit badges
    end

    def render_model_input_form
        model_name = params[:modelName]
        if model_name == "level"
            @levels = Level.all.order(level: :asc)
        elsif model_name == "badge"
            @badges = Badge.all.order(created_at: :desc)
        elsif model_name == "challenge"
            @challenges = Challenge.all.order(created_at: :desc)
        end

        respond_to do |format|
          format.html {
            render partial: "#{model_name}_input"
          }      
        end
    end

    def update_levels
        error_array = []
        params[:data].values.each do |value| 
            delete = value[:delete] == "true" ? true : false
            id = value[:id].blank? ? nil : value[:id].to_i
            inputID = value[:inputId]
            level = value[:level]
            criteria = value[:criteria]

            result = Level.update_level(delete,id,level,criteria)

            if !result[:status] 
                error_array.push({inputId:inputID,message:result[:message],elements:result[:elements]})
            end
        end

        if error_array.length > 0
            status = false
            message = "Encountered some errors while updating the levels. See the highlighted cells"
            data = {errorInputIds: error_array.map {|error| error[:inputId]}}
            actions = error_array.map {|error| error[:elements].map{|element| {action:"change_css",element:"#level .update-instance[data-instance-id=#{error[:inputId]}] .updateInput##{element.to_s}",css:{attribute:"border",value:"1px solid red"} } } }.flatten
            actions.push({action:"function_call",function:"reCheck('level',receivedDataFromAJAX.data.errorInputIds,'update')"})
        else
            status = true
            message = "Successfully saved"
            data = nil
            actions = [{action:"function_call",function:"setTimeout(function(){ loadInputForm('level')},2000)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end                

    end


    def update_challenges
        error_array = []
        params[:data].values.each do |value| 
            delete = value[:delete] == "true" ? true : false
            id = value[:id].blank? ? nil : value[:id].to_i
            inputID = value[:inputId]
            name = value[:name]
            description = value[:description]
            instructions = value[:instructions]
            repeated_allowed = value[:repeated_allowed] == "true" ? true : false
            criteria = value[:criteria]
            reward = value[:reward]

            result = Challenge.update_challenge(delete,id,name,description,instructions,repeated_allowed,criteria,reward)

            if !result[:status] 
                error_array.push({inputId:inputID,message:result[:message],elements:result[:elements]})
            end
        end

        if error_array.length > 0
            status = false
            message = "Encountered some errors while updating the challenges. See the highlighted cells"
            data = {errorInputIds: error_array.map {|error| error[:inputId]}}
            actions = error_array.map {|error| error[:elements].map{|element| {action:"change_css",element:"#challenge .update-instance[data-instance-id=#{error[:inputId]}] .updateInput##{element.to_s}",css:{attribute:"border",value:"1px solid red"} } } }.flatten
            actions.push({action:"function_call",function:"reCheck('challenge',receivedDataFromAJAX.data.errorInputIds,'update')"})
        else
            status = true
            message = "Successfully saved"
            data = nil
            actions = [{action:"function_call",function:"setTimeout(function(){ loadInputForm('challenge')},2000)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end                

    end



    def update_badges
        error_array = []
        params[:data].values.each do |value| 
            delete = value[:delete] == "true" ? true : false
            id = value[:id].blank? ? nil : value[:id].to_i
            inputID = value[:inputId]
            name = value[:name]
            description = value[:description]
            criteria = value[:criteria]

            result = Badge.update_badge(delete,id,name,description,criteria)

            if !result[:status] 
                error_array.push({inputId:inputID,message:result[:message],elements:result[:elements]})
            end
        end

        if error_array.length > 0
            status = false
            message = "Encountered some errors while updating the badges. See the highlighted cells"
            data = {errorInputIds: error_array.map {|error| error[:inputId]}}
            actions = error_array.map {|error| error[:elements].map{|element| {action:"change_css",element:"#badge .update-instance[data-instance-id=#{error[:inputId]}] .updateInput##{element.to_s}",css:{attribute:"border",value:"1px solid red"} } } }.flatten
            actions.push({action:"function_call",function:"reCheck('badge',receivedDataFromAJAX.data.errorInputIds,'update')"})
        else
            status = true
            message = "Successfully saved"
            data = nil
            actions = [{action:"function_call",function:"setTimeout(function(){ loadInputForm('badge')},2000)"}]
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message,actions:actions,data:data}
          } 
        end                

    end



end
