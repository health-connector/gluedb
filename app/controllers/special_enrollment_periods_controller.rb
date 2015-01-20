class SpecialEnrollmentPeriodsController < ApplicationController

  def new
    @sep = SpecialEnrollmentPeriod.new(application_group_id: params[:application_group_id])
    @family = Family.find(params[:application_group_id])
    
  end

  def create
    @family = Family.find(params[:application_group_id])
    @sep = SpecialEnrollmentPeriod.new(params[:special_enrollment_period])

    if(@sep.valid?)
      @family.special_enrollment_periods << @sep
      redirect_to @family
    else
      render action: "new"
    end
  end
end
