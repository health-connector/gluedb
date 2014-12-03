class HbxEnrollment
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM   

  KINDS = %W[unassisted_qhp insurance_assisted_qhp employer_sponsored streamlined_medicaid emergency_medicaid hcr_chip]

  embedded_in :coverage_household
  embedded_in :tax_household

  field :kind, type: String
  field :enrollment_group_id, type: String
  field :applied_aptc_in_cents, type: Integer, default: 0
  field :elected_aptc_in_cents, type: Integer, default: 0
  field :is_active, type: Boolean, default: true 
  field :aasm_state, type: String

  field :policy_id, type: Integer

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

  index({policy_id: 1})

  def parent
    raise "undefined parent ApplicationGroup" unless application_group? 
    self.application_group
  end

  def policy=(policy_instance)
    return unless policy_instance.is_a? Policy
    self.policy_id = policy_instance._id
  end

  def policy
    Policy.find(self.policy_id) unless self.policy_id.blank?
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
