module Resources
  module V1
    class IndividualsController < ApplicationController
#      skip_before_filter :authenticate_me!

      def show
        @person = Person.where("members.hbx_member_id" => params[:id]).first

        if @person
          respond_to do |format|
            format.xml { render "people/show" }
          end
        else
          render :nothing => true, :status => 404
        end
      end
    end
  end
end
