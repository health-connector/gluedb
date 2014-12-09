class HbxEnrollmentMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_enrollment

  field :is_subscriber, type: Boolean, default: false
  field :applicant_id, type: Moped::BSON::ObjectId

  include BelongsToApplicant

  def application_group
    return nil unless hbx_enrollment
    hbx_enrollment.application_group
  end

  def is_subscriber?
    self.is_subscriber
  end

end
