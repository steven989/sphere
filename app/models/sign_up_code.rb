class SignUpCode < ActiveRecord::Base
    belongs_to :user
    validates :code, uniqueness: true

    def increment
        self.update_attributes(quantity_used:self.quantity_used.to_i+1)
    end

    def self.increment(code)
        SignUpCode.where(code:code).take.increment
    end

    def self.update_sign_up_code_non_user_codes(id,delete,code,quantity,valid_after,valid_before,active,description)
        if !id.blank?
            sign_up_codeObj = SignUpCode.find(id)
            if sign_up_codeObj
                if delete
                    sign_up_codeObj.destroy
                    status = true
                    message = "Signup code deleted"
                    elements = nil
                else
                    # evaluate the criteria to make sure it's actually good
                    evaluation_result = valid_before.nil? || valid_after.nil? || (valid_before && valid_after && valid_before >= valid_after)
                    if evaluation_result
                        sign_up_codeObj.assign_attributes(code:code,quantity:quantity,valid_after:valid_after,valid_before:valid_before,active:active,description:description)
                        begin
                            savedObj = sign_up_codeObj.save
                        rescue => error
                            status = false
                            message = "Signup code could not be updated: #{error.message}"
                            elements = nil                            
                        else
                            if savedObj
                                status = true
                                message = "Signup code successfully updated"
                                elements = nil
                            else
                                status = false
                                message = "Signup code could not be updated: #{sign_up_codeObj.errors.full_messages.join(', ')}"
                                elements = sign_up_codeObj.errors.messages.keys
                            end
                        end
                    else
                        status = false
                        message = "Expiry date can't be before the effective after date"
                        elements = nil
                    end
                end
            else
                status = true
                message = "Did not find ID. No action performed"
                elements = nil
            end 
        else
            # evaluate the criteria to make sure it's actually good
            evaluation_result = valid_before.nil? || valid_after.nil? || (valid_before && valid_after && valid_before >= valid_after)
            if evaluation_result
                sign_up_codeObj = SignUpCode.new(code:code,quantity:quantity,valid_after:valid_after,valid_before:valid_before,active:active,description:description,code_type:"admin_manually_entered")
                if sign_up_codeObj.save
                    status = true
                    message = "Signup code successfully updated"
                    elements = nil
                else
                    status = false
                    message = "Signup code could not be updated: #{sign_up_codeObj.errors.full_messages.join(', ')}"
                    elements = sign_up_codeObj.errors.messages.keys
                end
            else
                status = false
                message = "Expiry date can't be before the effective after date"
                elements = nil
            end
        end
        {status:status,message:message,elements:elements}
    end

    def self.check_if_code_is_valid(code)
        result = SignUpCode.where("code ilike ?", code)
        if result.length == 0
            {status:false,message:"#{code} is not a valid code. Please check to ensure you entered it correctly"}
        else
            code_object = result.take
            if code_object.quantity && code_object.quantity_used.to_i >= code_object.quantity
                {status:false,message:"#{code} has been fully redeemed"}
            elsif code_object.valid_after && (Date.today+1) < code_object.valid_after
                {status:false,message:"#{code} is valid after #{code_object.valid_after.strftime('%Y-%m-%d')}"}
            elsif code_object.valid_before && (Date.today-1) > code_object.valid_before
                {status:false,message:"#{code} has expired"}
            elsif !code_object.active
                {status:false,message:"#{code} is inactive"}
            else
                {status:true}
            end
        end
    end

    def self.generate_code
        # in the shape of SR3ZAZ
        letters_to_use = ["A","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","T","U","V","W","X","Y"]
        numbers_to_use = ["3","4","6","7","9"]
        code_candidate = ""
        6.times do |count|
            if count == 2
                code_candidate+= numbers_to_use.sample
            else
                code_candidate+= letters_to_use.sample
            end
        end
        code_candidate
    end

    def self.check_duplicate(code)
        SignUpCode.where(code:code).length == 0
    end

    def self.generate_duplicate_checked_code
        code_candidate = ""
        loop do 
            code_candidate = SignUpCode.generate_code    
            break if SignUpCode.check_duplicate(code_candidate)
        end
        code_candidate
    end

    def self.create_sign_up_codes(number=1,quantity_for_each_code=10,user=nil)
        user_id = user ? user.id : nil
        actual_number = user ? 1 : number
        actual_quantity = user ? user.user_setting.value_evaled[:number_of_invites] : quantity_for_each_code
        number.times do |number|
            code = SignUpCode.generate_duplicate_checked_code
            SignUpCode.create(
                user_id:user_id,
                code:code,
                quantity:actual_quantity,
                description:nil,
                valid_after:nil,
                valid_before:nil,
                code_type:"admin_generated",
                active:true
            )
        end
    end

end
