class ApplicationGroupsController < ApplicationController
  def index
    @application_groups = ApplicationGroup.page(params[:page]).per(15)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @employers }
    end
  end

  def show
    @application_group = ApplicationGroup.find(params[:id])

    @primary_applicant = @application_group.primary_applicant
  end

  def edit
    @edit_form = EditApplicationGroupForm.new(params)
  end

  def update
    @application_group = ApplicationGroup.find(params[:id])
    people_to_remove.each { |p| @application_group.people.delete(p) }
    @application_group.save
  end

  def applicant_links
    @application_group = ApplicationGroup.find(params[:id])
    @applicants = @application_group.active_applicants
  end

  private
    def people_to_remove
      ppl_hash = params[:edit_application_group_form].fetch(:people_attributes) { {} }

      ids = []
      ppl_hash.each_pair do |index, person|
        ids << person[:person_id] if(person[:remove_selected] == "1")
      end
      @application_group.people.select { |p| ids.include?(p._id.to_s) }
    end

end
