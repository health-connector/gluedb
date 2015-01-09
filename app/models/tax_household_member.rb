class TaxHouseholdMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :tax_household
  embeds_many :financial_statements

  field :applicant_id, type: Moped::BSON::ObjectId

  field :is_ia_eligible, type: Boolean, default: false
  field :is_medicaid_chip_eligible, type: Boolean, default: false
  field :is_subscriber, type: Boolean, default: false
  field :is_primary_applicant, type: Boolean, default: false

  include BelongsToApplicant

  validate :strictly_boolean

  def eligibility_determinations
    return nil unless tax_household
    tax_household.eligibility_determinations
  end

  def application_group
    return nil unless tax_household
    tax_household.application_group
  end

  def is_ia_eligible?
    self.is_ia_eligible
  end

  def is_medicaid_chip_eligible?
    self.is_medicaid_chip_eligible
  end

  def is_subscriber?
    self.is_subscriber
  end

  def is_primary_applicant?
    self.applicant.is_primary_applicant
  end

  def strictly_boolean
    unless is_ia_eligible.is_a? Boolean
      self.errors.add(:base, "is_ia_eligible should be a boolean")
    end

    unless is_medicaid_chip_eligible.is_a? Boolean
      self.errors.add(:base, "is_medicaid_chip_eligible should be a boolean")
    end

    unless is_subscriber.is_a? Boolean
      self.errors.add(:base, "is_subscriber should be a boolean")
    end

    unless is_primary_applicant.is_a? Boolean
      self.errors.add(:base, "is_primary_applicant should be a boolean")
    end
  end
end
