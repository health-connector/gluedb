class CoverageHousehold
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasApplicants

  # The pool of all applicants eligible for enrollment during a certain time period

  embedded_in :household

  field :submitted_at, type: DateTime

  embeds_many :coverage_household_members
  accepts_nested_attributes_for :coverage_household_members

  validate :presence_of_coverage_household_members

  def presence_of_coverage_household_members
    if self.coverage_household_members.size == 0
      self.errors.add(:base, "Should have atleast one coverage_household_member")
    end
  end

  def application_group
    return nil unless household
    household.application_group
  end

  def applicant_ids
    coverage_household_members.map(&:applicant_id)
  end


end
