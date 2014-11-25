class ApplicantLink
  include Mongoid::Document

  embedded_in :tax_household
  belongs_to :financial_statement
  embedded_in :eligibility_determination
  embedded_in :hbx_enrollment
  embedded_in :hbx_enrollment_exemption
  embedded_in :qualifying_life_event

  field :person_id, type: Moped::BSON::ObjectId
  # field :tax_household_id, type: Moped::BSON::ObjectId
  # field :financial_statement_id, type: Moped::BSON::ObjectId

  field :is_primary_applicant, type: Boolean, default: false
  field :premium_amount_in_cents, type: Integer

  field :is_ia_eligible, type: Boolean, default: false
  field :is_medicaid_chip_eligible, type: Boolean, default: false

  field :is_active, type: Boolean, default: true

  def person=(person_instance)
    return unless person_instance.is_a? Person
    self.person_id = person_instance._id
    # parent.applicants << person_instance  # Applicant associations are tracked at ApplicationGroup level
  end

  def person
    Person.find(self.person_id) unless self.person_id.blank?
  end

  def premium_amount_in_dollars=(dollars)
    self.premium_amount_in_cents = (Rational(dollars) * Rational(100)).to_i

  end

  def premium_amount_in_dollars
    (Rational(premium_amount_in_cents) / Rational(100)).to_f if premium_amount_in_cents
  end

  def is_active?
    self.is_active
  end

  def is_primary_applicant?
    self.is_primay_applicant
  end

end