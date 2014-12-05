class ApplicationGroupBuilder

  attr_reader :application_group

  def initialize
    @application_group = ApplicationGroup.new
  end

  def add_applicant(applicant)
    @application_group.applicants << applicant
  end
end