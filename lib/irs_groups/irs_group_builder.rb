class IrsGroupBuilder

=begin
  def initialize(application_group)
    @application_group = application_group
  end
=end

  def initialize(application_group_id)
    @application_group = ApplicationGroup.find(application_group_id)
    puts "@application_group #{@application_group.households.inspect}"
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


  def retain_irs_group?

    puts "@application_group.households.size #{@application_group.households.size}"
    all_households = @application_group.households.sort_by(&:submitted_at)

    puts "all_households #{all_households.length}"
    return false if all_households.length == 1

    previous_household, current_household = all_households[all_households.length-2, all_households.length]

    puts "#{current_household.coverage_households.length} == #{previous_household.coverage_households.length}"
    current_household.coverage_households.length == previous_household.coverage_households.length

  end

  def assign_exisiting_irs_group_to_new_household

    all_households = @application_group.households.sort_by(&:submitted_at)

    previous_household, current_household = all_households[all_households.length-2, all_households.length]

    current_household.irs_group_id =  previous_household.irs_group_id
    current_household.save!

    puts "current_household.irs_group_id #{current_household.irs_group_id}"

  end
end