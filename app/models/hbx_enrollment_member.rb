class HbxEnrollmentMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_enrollment

  field :is_subscriber, type: Boolean, default: false
  field :applicant_id, type: Moped::BSON::ObjectId

  def application_group
    hbx_enrollment.application_group
  end

  # many_to_many_through :tax_household
  def applicant
    application_group.applicants.detect { |apl| apl._id == self.applicant_id }
  end

  def applicant=(applicant_instance)
    return unless applicant_instance.is_a? Applicant
    self.applicant_instance_id = applicant._id
  end


  def is_subscriber?
    self.is_subscriber
  end

end
