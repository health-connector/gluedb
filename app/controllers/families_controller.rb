class FamiliesController < ApplicationController
  def index
    @families = Family.page(params[:page]).per(15)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @employers }
    end
  end

  def show
    @family = Family.find(params[:id])

    @primary_applicant = @family.primary_applicant
  end

  def edit
    @edit_form = EditFamilyForm.new(params)
  end

  def update
    @family = Family.find(params[:id])
    people_to_remove.each { |p| @family.people.delete(p) }
    @family.save
  end

  def family_member_links
    @family = Family.find(params[:id])
    @family_members = @family.active_family_members
  end

  private
    def people_to_remove
      ppl_hash = params[:edit_family_form].fetch(:people_attributes) { {} }

      ids = []
      ppl_hash.each_pair do |index, person|
        ids << person[:person_id] if(person[:remove_selected] == "1")
      end
      @family.people.select { |p| ids.include?(p._id.to_s) }
    end

end
