class IrsGroupBuilder

  def initialize(application_group)

    if(application_group.is_a? Family)
      @family = application_group
    else
      @family = Family.find(application_group)
    end
  end

  def build
    @irs_group = @family.irs_groups.build
  end

  def save
    @irs_group.save!
    @family.active_household.irs_group_id = @irs_group._id
    @family.save!
  end

  def update
      if retain_irs_group?
          assign_exisiting_irs_group_to_new_household
      end
      #set_current_and_previous_households
      #decision_matrix
  end

  # returns true if we take the irsgroup from previous household and apply it to new household.
  # this happens when the number of coverage households has remained the same.
  # returns false otherswise. i.e. when we have to split/merge irsgroups
  def retain_irs_group?
    all_households = @family.households.sort_by(&:submitted_at)
    return false if all_households.length == 1

    previous_household, current_household = all_households[all_households.length-2, all_households.length]
    current_household.coverage_households.length == previous_household.coverage_households.length
  end

  def assign_exisiting_irs_group_to_new_household
    all_households = @family.households.sort_by(&:submitted_at)
    previous_household, current_household = all_households[all_households.length-2, all_households.length]
    current_household.irs_group_id =  previous_household.irs_group_id
    current_household.save!
  end

  def decision_matrix

    if coverage_household_changed? && tax_household_changed?
      manipulate_irs_group
    elsif coverage_household_changed? && !tax_household_changed?
      retain_irs_group
    elsif !coverage_household_changed? && tax_household_changed?
      retain_irs_group
    else #!coverage_household_changed? && !tax_household_changed?
      retain_irs_group
    end

  end

  def coverage_household_changed?
    if @current_household.coverage_households.length != @previous_household.coverage_households.length
      return true
    else
      return false
    end
  end

  def tax_household_changed?
    if @current_household.tax_households.length != @previous_household.tax_households.length
      return true
    else
      return false
    end
  end

  def manipulate_irs_group

  end

  def retain_irs_group
    @current_household.irs_group_id =  @previous_household.irs_group_id
    current_household.save!
  end

  def set_current_and_previous_households
    all_households = @family.households.sort_by(&:submitted_at)
    @previous_household, @current_household = all_households[all_households.length-2, all_households.length]
  end

end