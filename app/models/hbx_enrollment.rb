class HbxEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  KINDS = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]

  embedded_in :application_group

  field :kind, type: String
  field :enrollment_group_id, type: String
  field :plan_id, type: Moped::BSON::ObjectId
  field :allocated_aptc_in_cents, type: Integer, default: 0
  field :applied_aptc_in_cents, type: Integer, default: 0
  field :elected_aptc_in_cents, type: Integer, default: 0
  field :is_active, type: Boolean, default: true 
  field :aasm_state, type: String

  # embedded association: belongs_to IrsGroup 
  field :policy_id,    type: Integer
  field :irs_group_id, type: Moped::BSON::ObjectId
  field :employer_id,  type: Moped::BSON::ObjectId
  field :broker_id,    type: Moped::BSON::ObjectId
  field :primary_applicant_id, type: Moped::BSON::ObjectId
  field :eligibility_determination_id, type: Moped::BSON::ObjectId
  field :qualifying_life_event_id, type: Moped::BSON::ObjectId

  embeds_many :applicant_links
  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  validates :kind, 
    					presence: true,
    					allow_blank: false,
    					allow_nil:   false,
    					inclusion: {in: KINDS, message: "%{value} is not a valid enrollment type"}

  validates :allocated_aptc_in_cents,
              allow_nil: true, 
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def parent
    raise "undefined parent ApplicationGroup" unless application_group? 
    self.application_group
  end

  def employer=(employer_instance)
    return unless employer_instance.is_a? Employer
    self.employer_id = employer_instance._id
  end

  def employer
    Employer.find(self.employer_id) unless self.employer_id.blank?
  end

  def broker=(broker_instance)
    return unless broker_instance.is_a? Broker
    self.broker_id = broker_instance._id
  end

  def broker
    Broker.find(self.broker_id) unless self.broker_id.blank?
  end

  def qualifying_life_event=(qle_instance)
    return unless qle_instance.is_a? QualifyingLifeEvent
    self.qualifying_life_event_id = qle_instance._id
  end

  def qualifying_life_event
    parent.qualifying_life_event.find(self.qualifying_life_event_id)
  end

  def policy=(policy_instance)
    return unless policy_instance.is_a? Policy
    self.policy_id = policy_instance._id
    parent.hbx_enrollment_policies << policy_instance  # Policies are tracked at ApplicationGroup level
  end

  def policy
    Policy.find(self.policy_id) unless self.policy_id.blank?
  end

  def plan=(plan_instance)
    return unless plan_instance.is_a? Plan
    self.plan_id = plan_instance._id
  end

  def plan
    Plan.find(self.plan_id) unless self.plan_id.blank?
  end

  def irs_group=(irs_instance)
    return unless irs_instance.is_a? IrsGroup
    self.irs_group_id = irs_instance._id
  end

  def irs_group
    parent.irs_groups.find(self.irs_group_id)
  end

  def primary_applicant=(person_instance)
    return unless person_instance.is_a? Person
    self.primary_applicant_id = person_instance._id
  end

  def primary_applicant
    Person.find(self.primary_applicant_id) unless self.primary_applicant_id.blank?
  end

  # Insurance assistance determination
  def eligibility_determination=(eligibility_determination_instance)
    return unless eligibility_determination_instance.is_a? EligibilityDetermination
    self.eligibility_determination_id = eligibility_determination_instance._id
  end

  def eligibility_determination
    parent.eligibility_determinations.find(self.eligibility_determination_id) unless self.eligibility_determination_id.blank?
  end

  def allocated_aptc_in_dollars=(dollars)
    self.allocated_aptc_in_cents = (Rational(dollars) * Rational(100)).to_i
  end

  def allocated_aptc_in_dollars
    (Rational(allocated_aptc_in_cents) / Rational(100)).to_f if allocated_aptc_in_cents
  end

  def applied_aptc_in_dollars=(dollars)
    self.applied_aptc_in_cents = (Rational(dollars) * Rational(100)).to_i
  end

  def applied_aptc_in_dollars
    (Rational(applied_aptc_in_cents) / Rational(100)).to_f if applied_aptc_in_cents
  end

  def elected_aptc_in_dollars=(dollars)
    self.elected_aptc_in_cents = (Rational(dollars) * Rational(100)).to_i
  end

  def elected_aptc_in_dollars
    (Rational(elected_aptc_in_cents) / Rational(100)).to_f if elected_aptc_in_cents
  end

  aasm do
    state :enrollment_closed, initial: true
  end

  def is_active?
    self.is_active
  end


end
