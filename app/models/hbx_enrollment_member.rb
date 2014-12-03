class HbxEnrollmentMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_enrollment

  field :is_subscriber, type: Boolean, default: false
  field :applicant_id, type: Moped::BSON::ObjectId

  def parent
    raise "undefined parent ApplicationGroup" unless application_group? 
    self.hbx_enrollment.coverage_household.application_group
  end

  # many_to_many_through :tax_household
  def applicant
    parent.applicant.where(:hbx_enrollment_member_id => self.id)
  end

  def applicant=(applicant_instance)
    return unless applicant_instance.is_a? Applicant
    self.applicant_instance_id = applicant._id
  end


  def is_subscriber?
    self.is_subscriber
  end

end
