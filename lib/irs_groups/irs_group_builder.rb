class IrsGroupBuilder

  def initialize(application_group)
    @application_group = application_group
  end

  def build
    @irs_group = @application_group.irs_groups.build
  end
end