class FamilyMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :family

  # Person responsible for this family
  field :is_primary_applicant, type: Boolean, default: false

  # Person is applying for coverage
  field :is_coverage_applicant, type: Boolean, default: true

  # Person who authorizes auto-renewal eligibility check
  field :is_consent_applicant, type: Boolean, default: false

  field :is_active, type: Boolean, default: true

  field :person_id, type: Moped::BSON::ObjectId
  field :broker_id, type: Moped::BSON::ObjectId
  field :mes, type: Boolean, default: false #minimum essential coverage, should be renamed to mec

  embeds_many :hbx_enrollment_exemptions
  accepts_nested_attributes_for :hbx_enrollment_exemptions

  embeds_many :comments, cascade_callbacks: true
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  index({person_id: 1})
  index({broker_id:  1})
  index({is_primary_applicant: 1})

  validates_presence_of :person_id, :is_primary_applicant, :is_coverage_applicant

  def parent
    raise "undefined parent family" unless family
    self.family
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

  def is_coverage_applicant?
    self.is_coverage_applicant
  end

  def is_active?
    self.is_active
  end

end
