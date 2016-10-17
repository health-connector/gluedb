module Resources
  module V1
    class FamiliesController < ApplicationController
      skip_before_filter :authenticate_me!

      def show
        @family = Family.where(hbx_assigned_id: params[:id]).first

        if @family
          respond_to do |format|
            format.xml { render "family/show" }
          end
        else
          render :nothing => true, :status => 404
        end
      end

    end
  end
end