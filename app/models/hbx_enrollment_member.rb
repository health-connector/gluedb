class HbxEnrollmentMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_enrollment

  field :applicant_id, type: Moped::BSON::ObjectId
  field :premium_amount_in_dollars, type: Integer
  field :is_subscriber, type: Boolean, default: false

  include BelongsToApplicant

  validates_presence_of :applicant_id

  def application_group
    return nil unless hbx_enrollment
    hbx_enrollment.application_group
  end

  def is_subscriber?
    self.is_subscriber
  end

end
