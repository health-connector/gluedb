module Resources
  module V1
    class FamiliesController < ApplicationController
      skip_before_filter :authenticate_me!

      def show
        @family = Family.where(hbx_assigned_id: params[:id]).first
        @family_people = Person.where(:_id => {"$in" => @family.family_members.map(&:person_id)}).to_a
        @family.family_members.each do |fm|
          fm.person = @family_people.detect { |fmp| fmp.id == fm.person_id }
        end

        if @family
          respond_to do |format|
            format.xml { render "families/show" }
          end
        else
          render :nothing => true, :status => 404
        end
      end

    end
  end
end
