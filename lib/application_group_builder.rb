class ApplicationGroupBuilder

  attr_reader :application_group

  def initialize(param)
    @application_group = ApplicationGroup.new(param)
  end

  def add_applicant(applicant)
    @application_group.applicants << applicant
  end

  def add_applicants(applicants)
    @application_group.applicants = applicants
  end
end