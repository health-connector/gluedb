class IndividualsController < ApplicationController



  def index
    id = params[:id]
    if params[:id].present?
      if Person.where("member.hbx_member_id" => id).present?
        @person = Person.where("member.hbx_member_id" => id).first
      else
        #some warning messages
      end
     else
      #some warning messages
     end
    respond_to do |format|
      format.xml { render  "people/show"}
    end
  end
end
