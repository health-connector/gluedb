class TaxHouseholdMember
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :tax_household
  embeds_many :financial_statements
  embeds_many :eligibility_determinations

  field :applicant_id, type: Moped::BSON::ObjectId

  field :is_ia_eligible, type: Boolean, default: false
  field :is_medicaid_chip_eligible, type: Boolean, default: false
  field :is_subscriber, type: Boolean, default: false

  def parent
    self.tax_household.application_group
  end

  def applicant
    parent.applicant.find(self.applicant_id) unless self.applicant_id.blank?
  end

  def applicant=(applicant_instance)
    return unless applicant_instance.is_a? Applicant
    self.applicant_instance_id = applicant._id
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

end
