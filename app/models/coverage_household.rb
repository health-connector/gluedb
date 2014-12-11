class CoverageHousehold
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasApplicants

  # The pool of all applicants eligible for enrollment during a certain time period

  embedded_in :household
  
  field :effective_start_date, type: Date
  field :effective_end_date, type: Date
  field :submitted_at, type: DateTime

  embeds_many :coverage_household_members
  accepts_nested_attributes_for :coverage_household_members


  def application_group
    return nil unless household
    household.application_group
  end

  def applicant_ids
    coverage_household_members.map(&:applicant_id)
  end

end
