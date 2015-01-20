class IrsGroupBuilder

  def initialize(application_group)

    if(application_group.is_a? String)
      @application_group = ApplicationGroup.find(application_group)
    else
      @application_group = application_group
    end
  end

  def build
    @irs_group = @application_group.irs_groups.build
  end

  def save
    @irs_group.save!
    @application_group.active_household.irs_group_id = @irs_group._id
    @application_group.save!
  end

  def update
    if retain_irs_group?
      assign_exisiting_irs_group_to_new_household
    end
  end


  # returns true if we take the irsgroup from previous household and apply it to new household.
  # this happens when the number of coverage households has remained the same.
  # returns false otherswise. i.e. when we have to split/merge irsgroups
  def retain_irs_group?
    all_households = @application_group.households.sort_by(&:submitted_at)
    return false if all_households.length == 1

    previous_household, current_household = all_households[all_households.length-2, all_households.length]
    current_household.coverage_households.length == previous_household.coverage_households.length
  end

  def assign_exisiting_irs_group_to_new_household
    all_households = @application_group.households.sort_by(&:submitted_at)
    previous_household, current_household = all_households[all_households.length-2, all_households.length]
    current_household.irs_group_id =  previous_household.irs_group_id
    current_household.save!
  end
end