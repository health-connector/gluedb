class CoverageHouseholdMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :coverage_household

  field :applicant_id, type: Moped::BSON::ObjectId
  field :is_subscriber, type: Boolean, default: false


  def parent
    self.coverage_household.application_group
  end

  def applicant
    parent.applicant.find(self.applicant_id) unless self.applicant_id.blank?
  end

  def applicant=(applicant_instance)
    return unless applicant_instance.is_a? Applicant
    self.applicant_instance_id = applicant._id
  end

end
