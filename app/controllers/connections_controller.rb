class ConnectionsController < ApplicationController

    def create_note
        ConnectionNote.create(user_id:current_user.id,connection_id:params[:id],notes:params[:notes])
        redirect_to :root 
    end

end
