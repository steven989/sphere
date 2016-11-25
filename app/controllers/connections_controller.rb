class ConnectionsController < ApplicationController

    def create_note
        ConnectionNote.create(user_id:current_user.id,connection_id:params[:id],notes:params[:notes])
        redirect_to :root 
    end

    def update
        connection = Connection.find(params[:connection_id])
        unless (params[:photo] == "undefined") || (params[:photo] == "null") || params[:photo].blank?
            connection.remove_photo!
            connection.save
            connection.photo = params[:photo]
        end
        connection.assign_attributes(
            id:params[:connection_id]
        )
        if connection.save 
            status = true
            message = "Connection successfully updated"
        else
            status = false
            message = "Connection could not be updated #{connection.errors.full_messages.join(', ')}"
        end

        respond_to do |format|
          format.json {
            render json: {status:status, message:message}
          } 
        end

    end

end
