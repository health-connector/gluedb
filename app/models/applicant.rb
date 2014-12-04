class Applicant
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application_group

  # Person responsible for this application group
  field :is_primary_applicant, type: Boolean, default: false

  # Person is applying for coverage
  field :is_coverage_applicant, type: Boolean, default: false

  # Person who authorizes auto-renewal eligibility check
  field :is_consent_applicant, type: Boolean, default: false

  field :person_id, type: Moped::BSON::ObjectId
  field :broker_id, type: Moped::BSON::ObjectId

  embeds_many :hbx_enrollment_exemptions
  embeds_many :employee_applicants

  embeds_many :comments, cascade_callbacks: true
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  index({person_id: 1})
  index({broker_id:  1})
  index({is_primary_applicant: 1})

  def parent
    raise "undefined parent ApplicationGroup" unless application_group? 
    self.application_group
  end

  def person=(person_instance)
    return unless person_instance.is_a? Person
    self.person_id = person_instance._id
  end

  def person
    Person.find(self.person_id) unless self.person_id.blank?
  end

  def households
    # TODO parent.households.coverage_households.where()
  end

  def broker=(broker_instance)
    return unless broker_instance.is_a? Broker
    self.broker_id = broker_instance._id
  end

  def broker
    Broker.find(self.broker_id) unless self.broker_id.blank?
  end

  def is_primary_applicant?
    self.is_primary_applicant
  end

  def is_consent_applicant?
    self.is_consent_applicant
  end

  def is_active?
    self.is_active
  end

end
