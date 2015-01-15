class IrsGroupBuilder

  def initialize(application_group)
    @application_group = application_group
  end

  def build
    @irs_group = @application_group.irs_groups.build
    @application_group.active_household.irs_group_id = @irs_group.id
    @irs_group
  end
end