module Resources
  module V1
    class PoliciesController < ApplicationController
      skip_before_filter :authenticate_me!

      def show
        @policy = Policy.where("eg_id" => params[:id]).first

        if @policy
          respond_to do |format|
            format.xml { render "policies/show" }
          end
        else
          render :nothing => true, :status => 404
        end
      end
    end
  end
end
